using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Notification;
using MosPosudit.Model.Responses;
using MosPosudit.Model.Responses.Notification;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class NotificationController : BaseCrudController<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest>
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService service) : base(service)
        {
            _notificationService = service;
        }

        [HttpGet]
        public override async Task<Model.Responses.PagedResult<NotificationResponse>> Get([FromQuery] NotificationSearchObject? search = null)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            search ??= new NotificationSearchObject();
            search.UserId = userId;
            search.PageSize = 50;
            return await base.Get(search);
        }

        [HttpGet("unread")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var count = await _notificationService.GetUnreadCountForUser(userId);
            return Ok(new { unreadCount = count });
        }

        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            await _notificationService.MarkAsRead(id, userId);
            return Ok();
        }

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            await _notificationService.MarkAllAsRead(userId);
            return Ok();
        }

    }
} 