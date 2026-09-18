using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Menzilim.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDailyTaskContentLink : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ContentId",
                table: "DailyTasks",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_DailyTasks_ContentId",
                table: "DailyTasks",
                column: "ContentId");

            migrationBuilder.AddForeignKey(
                name: "FK_DailyTasks_Contents_ContentId",
                table: "DailyTasks",
                column: "ContentId",
                principalTable: "Contents",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DailyTasks_Contents_ContentId",
                table: "DailyTasks");

            migrationBuilder.DropIndex(
                name: "IX_DailyTasks_ContentId",
                table: "DailyTasks");

            migrationBuilder.DropColumn(
                name: "ContentId",
                table: "DailyTasks");
        }
    }
}
