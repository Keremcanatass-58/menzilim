using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Menzilim.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddContentProgressAndProfessionUniqueIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserContentProgresses_UserId",
                table: "UserContentProgresses");

            migrationBuilder.DropIndex(
                name: "IX_ContentProfessions_ContentId",
                table: "ContentProfessions");

            migrationBuilder.CreateIndex(
                name: "IX_UserContentProgresses_UserId_ContentId",
                table: "UserContentProgresses",
                columns: new[] { "UserId", "ContentId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ContentProfessions_ContentId_ProfessionId",
                table: "ContentProfessions",
                columns: new[] { "ContentId", "ProfessionId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserContentProgresses_UserId_ContentId",
                table: "UserContentProgresses");

            migrationBuilder.DropIndex(
                name: "IX_ContentProfessions_ContentId_ProfessionId",
                table: "ContentProfessions");

            migrationBuilder.CreateIndex(
                name: "IX_UserContentProgresses_UserId",
                table: "UserContentProgresses",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ContentProfessions_ContentId",
                table: "ContentProfessions",
                column: "ContentId");
        }
    }
}
