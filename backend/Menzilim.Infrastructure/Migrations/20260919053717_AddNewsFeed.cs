using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Menzilim.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddNewsFeed : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "NewsItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Summary = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SourceName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SourceUrl = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    PublishedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NewsItems", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "NewsItemSkills",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    NewsItemId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SkillId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NewsItemSkills", x => x.Id);
                    table.ForeignKey(
                        name: "FK_NewsItemSkills_NewsItems_NewsItemId",
                        column: x => x.NewsItemId,
                        principalTable: "NewsItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_NewsItemSkills_Skills_SkillId",
                        column: x => x.SkillId,
                        principalTable: "Skills",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_NewsItems_SourceUrl",
                table: "NewsItems",
                column: "SourceUrl",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_NewsItemSkills_NewsItemId_SkillId",
                table: "NewsItemSkills",
                columns: new[] { "NewsItemId", "SkillId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_NewsItemSkills_SkillId",
                table: "NewsItemSkills",
                column: "SkillId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "NewsItemSkills");

            migrationBuilder.DropTable(
                name: "NewsItems");
        }
    }
}
