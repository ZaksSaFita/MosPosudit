using MosPosudit.Model.Requests.Order;
using MosPosudit.Model.Responses.Order;
using MosPosudit.Model.SearchObjects;

namespace MosPosudit.Services.Interfaces
{
    public interface IOrderService : ICrudService<OrderResponse, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
    }
}

