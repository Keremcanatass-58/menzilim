using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Menzilim.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddLivingProjectAndQuizExplanations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Explanation",
                table: "Questions",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsAvailable",
                table: "Professions",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<Guid>(
                name: "SkillId",
                table: "LearningItems",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "UserProjects",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LearningPathId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserProjects", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserProjects_LearningPaths_LearningPathId",
                        column: x => x.LearningPathId,
                        principalTable: "LearningPaths",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserProjects_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserProjectSteps",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LearningItemId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Order = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EvidenceUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserProjectSteps", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserProjectSteps_LearningItems_LearningItemId",
                        column: x => x.LearningItemId,
                        principalTable: "LearningItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserProjectSteps_UserProjects_UserProjectId",
                        column: x => x.UserProjectId,
                        principalTable: "UserProjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LearningItems_SkillId",
                table: "LearningItems",
                column: "SkillId");

            migrationBuilder.CreateIndex(
                name: "IX_UserProjects_LearningPathId",
                table: "UserProjects",
                column: "LearningPathId");

            migrationBuilder.CreateIndex(
                name: "IX_UserProjects_UserId_LearningPathId",
                table: "UserProjects",
                columns: new[] { "UserId", "LearningPathId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserProjectSteps_LearningItemId",
                table: "UserProjectSteps",
                column: "LearningItemId");

            migrationBuilder.CreateIndex(
                name: "IX_UserProjectSteps_UserProjectId_LearningItemId",
                table: "UserProjectSteps",
                columns: new[] { "UserProjectId", "LearningItemId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_LearningItems_Skills_SkillId",
                table: "LearningItems",
                column: "SkillId",
                principalTable: "Skills",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_LearningItems_Skills_SkillId",
                table: "LearningItems");

            migrationBuilder.DropTable(
                name: "UserProjectSteps");

            migrationBuilder.DropTable(
                name: "UserProjects");

            migrationBuilder.DropIndex(
                name: "IX_LearningItems_SkillId",
                table: "LearningItems");

            migrationBuilder.DropColumn(
                name: "Explanation",
                table: "Questions");

            migrationBuilder.DropColumn(
                name: "IsAvailable",
                table: "Professions");

            migrationBuilder.DropColumn(
                name: "SkillId",
                table: "LearningItems");
        }
    }
}
