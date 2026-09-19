using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Menzilim.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSkillRelations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "Skills",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<Guid>(
                name: "SkillId",
                table: "Quizzes",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ContentSkills",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ContentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SkillId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ContentSkills", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ContentSkills_Contents_ContentId",
                        column: x => x.ContentId,
                        principalTable: "Contents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ContentSkills_Skills_SkillId",
                        column: x => x.SkillId,
                        principalTable: "Skills",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SpecializationSkills",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SpecializationId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SkillId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SpecializationSkills", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SpecializationSkills_Skills_SkillId",
                        column: x => x.SkillId,
                        principalTable: "Skills",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SpecializationSkills_Specializations_SpecializationId",
                        column: x => x.SpecializationId,
                        principalTable: "Specializations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Skills_Name",
                table: "Skills",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Quizzes_SkillId",
                table: "Quizzes",
                column: "SkillId");

            migrationBuilder.CreateIndex(
                name: "IX_ContentSkills_ContentId_SkillId",
                table: "ContentSkills",
                columns: new[] { "ContentId", "SkillId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ContentSkills_SkillId",
                table: "ContentSkills",
                column: "SkillId");

            migrationBuilder.CreateIndex(
                name: "IX_SpecializationSkills_SkillId",
                table: "SpecializationSkills",
                column: "SkillId");

            migrationBuilder.CreateIndex(
                name: "IX_SpecializationSkills_SpecializationId_SkillId",
                table: "SpecializationSkills",
                columns: new[] { "SpecializationId", "SkillId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Quizzes_Skills_SkillId",
                table: "Quizzes",
                column: "SkillId",
                principalTable: "Skills",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Quizzes_Skills_SkillId",
                table: "Quizzes");

            migrationBuilder.DropTable(
                name: "ContentSkills");

            migrationBuilder.DropTable(
                name: "SpecializationSkills");

            migrationBuilder.DropIndex(
                name: "IX_Skills_Name",
                table: "Skills");

            migrationBuilder.DropIndex(
                name: "IX_Quizzes_SkillId",
                table: "Quizzes");

            migrationBuilder.DropColumn(
                name: "SkillId",
                table: "Quizzes");

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "Skills",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");
        }
    }
}
