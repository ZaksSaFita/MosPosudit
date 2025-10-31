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
        public async Task<IActionResult> GetUserMessages()
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var messages = await _chatService.GetUserMessages(userId);
                return Ok(messages);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        // Get all pending messages (for admin)
        [HttpGet("pending")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetPendingMessages()
        {
            try
            {
                var messages = await _chatService.GetPendingMessages();
                return Ok(messages);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        // Send message (user sends to admin)
        [HttpPost("send")]
        public async Task<IActionResult> SendMessage([FromBody] MessageSendRequest request)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var response = await _chatService.SendMessage(userId, request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        // Start chat (admin responds to user's first message)
        [HttpPost("{messageId}/start")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> StartChat(int messageId)
        {
            try
            {
                var adminId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                await _chatService.StartChat(messageId, adminId);
                return Ok(new { message = "Chat started successfully" });
            }
            catch (Exception ex)
            {
                if (ex.Message.Contains("not found"))
                    return NotFound(new { message = ex.Message });
                if (ex.Message.Contains("already active"))
                    return BadRequest(new { message = ex.Message });
                return StatusCode(500, new { message = ex.Message });
            }
        }

        // Send reply (admin or user)
        [HttpPost("reply")]
        public async Task<IActionResult> SendReply([FromBody] MessageSendRequest request, [FromQuery] int conversationUserId)
        {
            try
            {
                var currentUserId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var response = await _chatService.SendReply(currentUserId, conversationUserId, request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                if (ex.Message.Contains("not found"))
                    return BadRequest(new { message = ex.Message });
                return StatusCode(500, new { message = ex.Message });
            }
        }

        // Mark message as read
        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                await _chatService.MarkAsRead(id, userId);
                return Ok();
            }
            catch (Exception ex)
            {
                if (ex.Message.Contains("not found"))
                    return NotFound(new { message = ex.Message });
                return StatusCode(500, new { message = ex.Message });
            }
        }

    }
}

