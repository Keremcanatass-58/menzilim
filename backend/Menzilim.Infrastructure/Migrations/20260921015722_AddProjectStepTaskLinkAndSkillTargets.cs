using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Menzilim.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddProjectStepTaskLinkAndSkillTargets : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TargetLevel",
                table: "SpecializationSkills",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "UserProjectStepId",
                table: "DailyTasks",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_DailyTasks_UserProjectStepId",
                table: "DailyTasks",
                column: "UserProjectStepId");

            migrationBuilder.AddForeignKey(
                name: "FK_DailyTasks_UserProjectSteps_UserProjectStepId",
                table: "DailyTasks",
                column: "UserProjectStepId",
                principalTable: "UserProjectSteps",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DailyTasks_UserProjectSteps_UserProjectStepId",
                table: "DailyTasks");

            migrationBuilder.DropIndex(
                name: "IX_DailyTasks_UserProjectStepId",
                table: "DailyTasks");

            migrationBuilder.DropColumn(
                name: "TargetLevel",
                table: "SpecializationSkills");

            migrationBuilder.DropColumn(
                name: "UserProjectStepId",
                table: "DailyTasks");
        }
    }
}
