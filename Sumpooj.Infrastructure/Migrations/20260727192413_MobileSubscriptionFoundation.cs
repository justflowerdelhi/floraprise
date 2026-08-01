using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class MobileSubscriptionFoundation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MobileCustomers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    BusinessName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    OwnerName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Mobile = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    Email = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    City = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    State = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Country = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MobileCustomers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SubscriptionPlans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    PlanType = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    MonthlyPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    AnnualPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    LifetimePrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TrialDays = table.Column<int>(type: "integer", nullable: false),
                    OfflineDays = table.Column<int>(type: "integer", nullable: false),
                    GraceDays = table.Column<int>(type: "integer", nullable: false),
                    MaximumDevices = table.Column<int>(type: "integer", nullable: false),
                    MaximumStaff = table.Column<int>(type: "integer", nullable: false),
                    IncludedModulesJson = table.Column<string>(type: "jsonb", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubscriptionPlans", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "MobileUsers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileCustomerId = table.Column<Guid>(type: "uuid", nullable: false),
                    FullName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Mobile = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    Email = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    Status = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    PreferredLanguage = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    PreferredTheme = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MobileUsers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MobileUsers_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MobileUsers_MobileCustomers_MobileCustomerId",
                        column: x => x.MobileCustomerId,
                        principalTable: "MobileCustomers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MobileDevices",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    DeviceId = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Manufacturer = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    Model = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    Platform = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    OsVersion = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    AppVersion = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    PushToken = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true),
                    LastIpAddress = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    LastLoginAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    LastHeartbeatAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    LastSyncAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    Status = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MobileDevices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MobileDevices_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MobileDevices_MobileUsers_MobileUserId",
                        column: x => x.MobileUserId,
                        principalTable: "MobileUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MobileSubscriptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    SubscriptionPlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    TrialStartUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    TrialEndUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    StartUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    EndUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    GraceEndUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    LastValidatedUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    AutoRenew = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MobileSubscriptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MobileSubscriptions_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MobileSubscriptions_MobileUsers_MobileUserId",
                        column: x => x.MobileUserId,
                        principalTable: "MobileUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MobileSubscriptions_SubscriptionPlans_SubscriptionPlanId",
                        column: x => x.SubscriptionPlanId,
                        principalTable: "SubscriptionPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DeviceSessions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileDeviceId = table.Column<Guid>(type: "uuid", nullable: false),
                    RefreshToken = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: false),
                    ExpiresAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    LastSeenAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    Status = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeviceSessions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DeviceSessions_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DeviceSessions_MobileDevices_MobileDeviceId",
                        column: x => x.MobileDeviceId,
                        principalTable: "MobileDevices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FeatureEntitlements",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileSubscriptionId = table.Column<Guid>(type: "uuid", nullable: false),
                    FeatureKey = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FeatureEntitlements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FeatureEntitlements_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_FeatureEntitlements_MobileSubscriptions_MobileSubscriptionId",
                        column: x => x.MobileSubscriptionId,
                        principalTable: "MobileSubscriptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MobileLicenses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileDeviceId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileSubscriptionId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    IssuedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    ExpiryUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    RevokedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MobileLicenses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MobileLicenses_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MobileLicenses_MobileDevices_MobileDeviceId",
                        column: x => x.MobileDeviceId,
                        principalTable: "MobileDevices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MobileLicenses_MobileSubscriptions_MobileSubscriptionId",
                        column: x => x.MobileSubscriptionId,
                        principalTable: "MobileSubscriptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MobilePaymentTransactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileSubscriptionId = table.Column<Guid>(type: "uuid", nullable: false),
                    PaymentType = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    PaymentStatus = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    TransactionRef = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    GatewayOrderId = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    GatewayPaymentId = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Amount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    PaidAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    FailedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    RefundedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    FailureReason = table.Column<string>(type: "character varying(400)", maxLength: 400, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MobilePaymentTransactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MobilePaymentTransactions_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MobilePaymentTransactions_MobileSubscriptions_MobileSubscri~",
                        column: x => x.MobileSubscriptionId,
                        principalTable: "MobileSubscriptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TrialHistory",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    MobileSubscriptionId = table.Column<Guid>(type: "uuid", nullable: false),
                    ActionType = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    ActionAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "bytea", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TrialHistory", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TrialHistory_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TrialHistory_MobileSubscriptions_MobileSubscriptionId",
                        column: x => x.MobileSubscriptionId,
                        principalTable: "MobileSubscriptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DeviceSessions_CompanyId_MobileDeviceId_Status",
                table: "DeviceSessions",
                columns: new[] { "CompanyId", "MobileDeviceId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_DeviceSessions_MobileDeviceId",
                table: "DeviceSessions",
                column: "MobileDeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_DeviceSessions_RefreshToken",
                table: "DeviceSessions",
                column: "RefreshToken",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_FeatureEntitlements_CompanyId_MobileSubscriptionId_FeatureK~",
                table: "FeatureEntitlements",
                columns: new[] { "CompanyId", "MobileSubscriptionId", "FeatureKey" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_FeatureEntitlements_MobileSubscriptionId",
                table: "FeatureEntitlements",
                column: "MobileSubscriptionId");

            migrationBuilder.CreateIndex(
                name: "IX_MobileCustomers_CompanyId_IsDeleted",
                table: "MobileCustomers",
                columns: new[] { "CompanyId", "IsDeleted" });

            migrationBuilder.CreateIndex(
                name: "IX_MobileCustomers_CompanyId_Mobile",
                table: "MobileCustomers",
                columns: new[] { "CompanyId", "Mobile" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevices_CompanyId_MobileUserId_DeviceId",
                table: "MobileDevices",
                columns: new[] { "CompanyId", "MobileUserId", "DeviceId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevices_CompanyId_Status",
                table: "MobileDevices",
                columns: new[] { "CompanyId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevices_MobileUserId",
                table: "MobileDevices",
                column: "MobileUserId");

            migrationBuilder.CreateIndex(
                name: "IX_MobileLicenses_CompanyId_Status",
                table: "MobileLicenses",
                columns: new[] { "CompanyId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_MobileLicenses_MobileDeviceId",
                table: "MobileLicenses",
                column: "MobileDeviceId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MobileLicenses_MobileSubscriptionId",
                table: "MobileLicenses",
                column: "MobileSubscriptionId");

            migrationBuilder.CreateIndex(
                name: "IX_MobilePaymentTransactions_CompanyId_PaymentStatus",
                table: "MobilePaymentTransactions",
                columns: new[] { "CompanyId", "PaymentStatus" });

            migrationBuilder.CreateIndex(
                name: "IX_MobilePaymentTransactions_MobileSubscriptionId",
                table: "MobilePaymentTransactions",
                column: "MobileSubscriptionId");

            migrationBuilder.CreateIndex(
                name: "IX_MobilePaymentTransactions_TransactionRef",
                table: "MobilePaymentTransactions",
                column: "TransactionRef",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MobileSubscriptions_CompanyId_Status",
                table: "MobileSubscriptions",
                columns: new[] { "CompanyId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_MobileSubscriptions_MobileUserId",
                table: "MobileSubscriptions",
                column: "MobileUserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MobileSubscriptions_SubscriptionPlanId",
                table: "MobileSubscriptions",
                column: "SubscriptionPlanId");

            migrationBuilder.CreateIndex(
                name: "IX_MobileUsers_CompanyId_Mobile",
                table: "MobileUsers",
                columns: new[] { "CompanyId", "Mobile" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MobileUsers_CompanyId_Status",
                table: "MobileUsers",
                columns: new[] { "CompanyId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_MobileUsers_MobileCustomerId",
                table: "MobileUsers",
                column: "MobileCustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionPlans_Code",
                table: "SubscriptionPlans",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionPlans_IsActive_IsDeleted",
                table: "SubscriptionPlans",
                columns: new[] { "IsActive", "IsDeleted" });

            migrationBuilder.CreateIndex(
                name: "IX_TrialHistory_CompanyId_MobileSubscriptionId_ActionAtUtc",
                table: "TrialHistory",
                columns: new[] { "CompanyId", "MobileSubscriptionId", "ActionAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_TrialHistory_MobileSubscriptionId",
                table: "TrialHistory",
                column: "MobileSubscriptionId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DeviceSessions");

            migrationBuilder.DropTable(
                name: "FeatureEntitlements");

            migrationBuilder.DropTable(
                name: "MobileLicenses");

            migrationBuilder.DropTable(
                name: "MobilePaymentTransactions");

            migrationBuilder.DropTable(
                name: "TrialHistory");

            migrationBuilder.DropTable(
                name: "MobileDevices");

            migrationBuilder.DropTable(
                name: "MobileSubscriptions");

            migrationBuilder.DropTable(
                name: "MobileUsers");

            migrationBuilder.DropTable(
                name: "SubscriptionPlans");

            migrationBuilder.DropTable(
                name: "MobileCustomers");
        }
    }
}
