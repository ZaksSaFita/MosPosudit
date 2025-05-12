using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace MošPosudit.Services.Migrations
{
    /// <inheritdoc />
    public partial class rols : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1439));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1443));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1444));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1444));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1445));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1472));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1474));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1474));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1475));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1476));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 4, 10, 776, DateTimeKind.Utc).AddTicks(1477));

            migrationBuilder.InsertData(
                table: "Roles",
                columns: new[] { "Id", "Description", "Name" },
                values: new object[,]
                {
                    { 1, "Administrator role", "Admin" },
                    { 2, "Regular user role", "User" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8466));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8469));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8470));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8471));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8472));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8626));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8629));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8630));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8631));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8632));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 16, 54, 11, 215, DateTimeKind.Utc).AddTicks(8632));
        }
    }
}
