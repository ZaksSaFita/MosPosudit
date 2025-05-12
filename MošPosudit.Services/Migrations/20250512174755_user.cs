using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MošPosudit.Services.Migrations
{
    /// <inheritdoc />
    public partial class user : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeactivateTime",
                table: "Users");

            migrationBuilder.AddColumn<DateTime>(
                name: "DeactivationDate",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5429));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5432));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5433));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5434));

            migrationBuilder.UpdateData(
                table: "PaymentMethods",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5435));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5549));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5550));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5551));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5551));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5552));

            migrationBuilder.UpdateData(
                table: "PaymentStatuses",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2025, 5, 12, 17, 47, 55, 217, DateTimeKind.Utc).AddTicks(5553));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeactivationDate",
                table: "Users");

            migrationBuilder.AddColumn<DateTime>(
                name: "DeactivateTime",
                table: "Users",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

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
        }
    }
}
