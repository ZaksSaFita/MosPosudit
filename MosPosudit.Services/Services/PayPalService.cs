using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Http;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace MosPosudit.Services.Services
{
    public interface IPayPalService
    {
        Task<string?> CreatePaymentOrderAsync(decimal amount, string currency, int rentalId, string returnUrl, string cancelUrl);
        Task<bool> CapturePaymentAsync(string orderId);
    }

    public class PayPalService : IPayPalService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<PayPalService> _logger;
        private readonly HttpClient _httpClient;
        private readonly string _clientId;
        private readonly string _secret;
        private readonly string _mode;
        private string? _accessToken;
        private DateTime? _tokenExpiresAt;

        public PayPalService(IConfiguration configuration, ILogger<PayPalService> logger, IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _clientId = configuration["PayPal:ClientId"] ?? throw new InvalidOperationException("PayPal ClientId is not configured");
            _secret = configuration["PayPal:Secret"] ?? throw new InvalidOperationException("PayPal Secret is not configured");
            _mode = configuration["PayPal:Mode"] ?? "sandbox";
        }

        private string BaseUrl => _mode.ToLower() == "live" 
            ? "https://api-m.paypal.com" 
            : "https://api-m.sandbox.paypal.com";

        private async Task<string> GetAccessTokenAsync()
        {
            // Check if we have a valid token
            if (_accessToken != null && _tokenExpiresAt.HasValue && DateTime.UtcNow < _tokenExpiresAt.Value.AddMinutes(-5))
            {
                return _accessToken;
            }

            try
            {
                var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_clientId}:{_secret}"));
                
                var request = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}/v1/oauth2/token");
                request.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);
                request.Content = new FormUrlEncodedContent(new[]
                {
                    new KeyValuePair<string, string>("grant_type", "client_credentials")
                });

                var response = await _httpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();

                var json = await response.Content.ReadAsStringAsync();
                var tokenResponse = JsonSerializer.Deserialize<JsonElement>(json);
                
                _accessToken = tokenResponse.GetProperty("access_token").GetString();
                var expiresIn = tokenResponse.GetProperty("expires_in").GetInt32();
                _tokenExpiresAt = DateTime.UtcNow.AddSeconds(expiresIn);

                _logger.LogInformation("PayPal access token obtained successfully");
                return _accessToken!;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to obtain PayPal access token");
                throw;
            }
        }

        public async Task<string?> CreatePaymentOrderAsync(decimal amount, string currency, int rentalId, string returnUrl, string cancelUrl)
        {
            try
            {
                var accessToken = await GetAccessTokenAsync();

                // PayPal API requires snake_case property names
                var orderRequest = new Dictionary<string, object>
                {
                    ["intent"] = "CAPTURE",
                    ["purchase_units"] = new[]
                    {
                        new Dictionary<string, object>
                        {
                            ["reference_id"] = $"rental_{rentalId}",
                            ["description"] = $"MosPosudit Rental #{rentalId}",
                            ["amount"] = new Dictionary<string, object>
                            {
                                ["currency_code"] = currency,
                                ["value"] = amount.ToString("F2")
                            }
                        }
                    },
                    ["application_context"] = new Dictionary<string, object>
                    {
                        ["brand_name"] = "MosPosudit",
                        ["landing_page"] = "NO_PREFERENCE",
                        ["user_action"] = "PAY_NOW",
                        ["return_url"] = returnUrl,
                        ["cancel_url"] = cancelUrl
                    }
                };

                var json = JsonSerializer.Serialize(orderRequest, new JsonSerializerOptions
                {
                    WriteIndented = false
                });

                var request = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}/v2/checkout/orders");
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                request.Content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await _httpClient.SendAsync(request);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("PayPal order creation failed: {StatusCode} - {Response}", response.StatusCode, responseContent);
                    throw new Exception($"PayPal API error: {response.StatusCode} - {responseContent}");
                }

                var orderResponse = JsonSerializer.Deserialize<JsonElement>(responseContent);
                var links = orderResponse.GetProperty("links").EnumerateArray();
                
                foreach (var link in links)
                {
                    var rel = link.GetProperty("rel").GetString();
                    if (rel == "approve")
                    {
                        var approvalUrl = link.GetProperty("href").GetString();
                        _logger.LogInformation("PayPal order created successfully. Approval URL: {Url}", approvalUrl);
                        return approvalUrl;
                    }
                }

                _logger.LogWarning("PayPal order created but no approval URL found");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create PayPal order for rental {RentalId}", rentalId);
                throw;
            }
        }

        public async Task<bool> CapturePaymentAsync(string orderId)
        {
            try
            {
                var accessToken = await GetAccessTokenAsync();

                var request = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}/v2/checkout/orders/{orderId}/capture");
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                request.Content = new StringContent("{}", Encoding.UTF8, "application/json");

                var response = await _httpClient.SendAsync(request);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("PayPal payment capture failed: {StatusCode} - {Response}", response.StatusCode, responseContent);
                    return false;
                }

                var captureResponse = JsonSerializer.Deserialize<JsonElement>(responseContent);
                var status = captureResponse.GetProperty("status").GetString();
                
                _logger.LogInformation("PayPal payment captured. Order ID: {OrderId}, Status: {Status}", orderId, status);
                return status == "COMPLETED";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to capture PayPal payment for order {OrderId}", orderId);
                return false;
            }
        }
    }
}

