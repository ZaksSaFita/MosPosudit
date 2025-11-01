using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Message;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;
using System;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class MessageController : ControllerBase
    {
        private readonly IChatService _chatService;

        public MessageController(IChatService chatService)
        {
            _chatService = chatService ?? throw new ArgumentNullException(nameof(chatService));
        }

        // Get all messages for current user (client)
        [HttpGet("user")]
        public async Task<IEnumerable<Model.Responses.Message.MessageResponse>> GetUserMessages()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            return await _chatService.GetUserMessages(userId);
        }

        // Get all pending messages (for admin)
        [HttpGet("pending")]
        [Authorize(Roles = "Admin")]
        public async Task<IEnumerable<Model.Responses.Message.MessageResponse>> GetPendingMessages()
        {
            return await _chatService.GetPendingMessages();
        }

        // Send message (user sends to admin)
        [HttpPost("send")]
        public async Task<Model.Responses.Message.MessageResponse> SendMessage([FromBody] MessageSendRequest request)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            return await _chatService.SendMessage(userId, request);
        }

        // Start chat (admin responds to user's first message)
        [HttpPost("{messageId}/start")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> StartChat(int messageId)
        {
            var adminId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            await _chatService.StartChat(messageId, adminId);
            return Ok(new { message = "Chat started successfully" });
        }

        // Start chat with user directly (admin initiates chat)
        [HttpPost("start-with-user/{userId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> StartChatWithUser(int userId)
        {
            try
            {
                var adminId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                await _chatService.StartChatWithUser(adminId, userId);
                return Ok(new { message = "Chat started successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        // Send reply (admin or user)
        [HttpPost("reply")]
        public async Task<Model.Responses.Message.MessageResponse> SendReply([FromBody] MessageSendRequest request, [FromQuery] int conversationUserId)
        {
            var currentUserId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            return await _chatService.SendReply(currentUserId, conversationUserId, request);
        }

        // Mark message as read
        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            await _chatService.MarkAsRead(id, userId);
            return Ok();
        }

    }
}

