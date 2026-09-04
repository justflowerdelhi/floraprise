using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMobileOperationalParity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "DeliveryAddressLongitude",
                table: "Deliveries",
                newName: "DeliveryLongitude");

            migrationBuilder.RenameColumn(
                name: "DeliveryAddressLatitude",
                table: "Deliveries",
                newName: "DeliveryLatitude");

            migrationBuilder.AlterColumn<string>(
                name: "IncludedModulesJson",
                table: "SubscriptionPlans",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CheckInUtc",
                table: "StaffAttendanceRecords",
                type: "timestamp with time zone",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone");

            migrationBuilder.AddColumn<DateTime>(
                name: "AttendanceDate",
                table: "StaffAttendanceRecords",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "Notes",
                table: "StaffAttendanceRecords",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "OvertimeHours",
                table: "StaffAttendanceRecords",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "RewardPointsEarned",
                table: "Orders",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "RewardPointsRedeemed",
                table: "Orders",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceFingerprintHash",
                table: "MobileDevices",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DeviceName",
                table: "MobileDevices",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "MobileDevices",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "ExpenseCategoryId",
                table: "Expenses",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PaymentMode",
                table: "Expenses",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletedAtUtc",
                table: "Deliveries",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastLocationUtc",
                table: "Deliveries",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "StartedAtUtc",
                table: "Deliveries",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AnniversaryMonthDay",
                table: "Customers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BirthdayMonthDay",
                table: "Customers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CompanyName",
                table: "Customers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Department",
                table: "Customers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastOrderAtUtc",
                table: "Customers",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastRewardActivityAtUtc",
                table: "Customers",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "LifetimeRewardPoints",
                table: "Customers",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "PendingPaymentAmount",
                table: "Customers",
                type: "numeric",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "RedeemedRewardPoints",
                table: "Customers",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "RewardPoints",
                table: "Customers",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Associates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    AssociateCode = table.Column<string>(type: "text", nullable: false),
                    BusinessName = table.Column<string>(type: "text", nullable: false),
                    ContactPerson = table.Column<string>(type: "text", nullable: true),
                    Phone = table.Column<string>(type: "text", nullable: false),
                    Whatsapp = table.Column<string>(type: "text", nullable: true),
                    Email = table.Column<string>(type: "text", nullable: true),
                    City = table.Column<string>(type: "text", nullable: false),
                    State = table.Column<string>(type: "text", nullable: true),
                    Pincode = table.Column<string>(type: "text", nullable: false),
                    Address = table.Column<string>(type: "text", nullable: true),
                    GstNumber = table.Column<string>(type: "text", nullable: true),
                    Website = table.Column<string>(type: "text", nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    Types = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Associates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Barcodes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Value = table.Column<string>(type: "text", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Barcodes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Barcodes_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CashBookEntries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    TransactionType = table.Column<int>(type: "integer", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    CashIn = table.Column<decimal>(type: "numeric", nullable: false),
                    CashOut = table.Column<decimal>(type: "numeric", nullable: false),
                    RunningBalance = table.Column<decimal>(type: "numeric", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CashBookEntries", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CloudDesigns",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    BouquetId = table.Column<string>(type: "text", nullable: false),
                    ImageReference = table.Column<string>(type: "text", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: false),
                    SellingPricePaise = table.Column<int>(type: "integer", nullable: true),
                    Flowers = table.Column<string>(type: "text", nullable: false),
                    Occasion = table.Column<string>(type: "text", nullable: false),
                    Color = table.Column<string>(type: "text", nullable: false),
                    Collection = table.Column<string>(type: "text", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    IsFavorite = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CloudDesigns", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ExpenseCategories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Emoji = table.Column<string>(type: "text", nullable: false),
                    GroupName = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExpenseCategories", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "MorningPurchaseListItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ListDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductName = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    Unit = table.Column<string>(type: "text", nullable: false),
                    Supplier = table.Column<string>(type: "text", nullable: false),
                    Priority = table.Column<string>(type: "text", nullable: false),
                    Remarks = table.Column<string>(type: "text", nullable: false),
                    Purchased = table.Column<bool>(type: "boolean", nullable: false),
                    InventoryUpdated = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MorningPurchaseListItems", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "OccasionContacts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uuid", nullable: false),
                    RecipientName = table.Column<string>(type: "text", nullable: false),
                    Relationship = table.Column<string>(type: "text", nullable: false),
                    Occasion = table.Column<string>(type: "text", nullable: false),
                    OccasionDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    RecipientPhone = table.Column<string>(type: "text", nullable: false),
                    Company = table.Column<string>(type: "text", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: false),
                    ReminderEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    Source = table.Column<string>(type: "text", nullable: false),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OccasionContacts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "OccasionFollowUpActions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    SourceType = table.Column<string>(type: "text", nullable: false),
                    SourceId = table.Column<Guid>(type: "uuid", nullable: false),
                    OccurrenceDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    SnoozedTo = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OccasionFollowUpActions", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "OpeningCashEntries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OpeningCashEntries", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ReadyBouquetRecords",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    FinishedProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    RecipeId = table.Column<Guid>(type: "uuid", nullable: true),
                    ProductionId = table.Column<Guid>(type: "uuid", nullable: true),
                    InitialQuantity = table.Column<int>(type: "integer", nullable: false),
                    RemainingQuantity = table.Column<int>(type: "integer", nullable: false),
                    ShelfLifeDays = table.Column<int>(type: "integer", nullable: false),
                    RefreshAfterDays = table.Column<int>(type: "integer", nullable: false),
                    ProducedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LastRefreshAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ExpiryAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Location = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    Note = table.Column<string>(type: "text", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReadyBouquetRecords", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ReadyBouquetRefreshEvents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    BatchId = table.Column<Guid>(type: "uuid", nullable: false),
                    ActionType = table.Column<string>(type: "text", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    WastageQuantity = table.Column<int>(type: "integer", nullable: false),
                    Reason = table.Column<string>(type: "text", nullable: true),
                    Note = table.Column<string>(type: "text", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReadyBouquetRefreshEvents", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SchedulerRecords",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Type = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    Priority = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    ScheduledAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    NextReminderAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DeadlineAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: false),
                    LinkedCustomerId = table.Column<Guid>(type: "uuid", nullable: true),
                    LinkedOrderId = table.Column<Guid>(type: "uuid", nullable: true),
                    AssignedStaffId = table.Column<Guid>(type: "uuid", nullable: true),
                    Producer = table.Column<string>(type: "text", nullable: false),
                    SourceRef = table.Column<string>(type: "text", nullable: false),
                    RequiresConfirmation = table.Column<bool>(type: "boolean", nullable: false),
                    RequiresAlarm = table.Column<bool>(type: "boolean", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DeletedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SchedulerRecords", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "WhatsAppAccounts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MemberId = table.Column<int>(type: "integer", nullable: false),
                    BusinessName = table.Column<string>(type: "text", nullable: false),
                    PhoneNumber = table.Column<string>(type: "text", nullable: false),
                    PhoneNumberId = table.Column<string>(type: "text", nullable: false),
                    WabaId = table.Column<string>(type: "text", nullable: false),
                    AccessToken = table.Column<string>(type: "text", nullable: false),
                    VerifyToken = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WhatsAppAccounts", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_StaffAttendanceRecords_CompanyId_StaffId_AttendanceDate",
                table: "StaffAttendanceRecords",
                columns: new[] { "CompanyId", "StaffId", "AttendanceDate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_DeliveryPersonId",
                table: "Orders",
                column: "DeliveryPersonId");

            migrationBuilder.CreateIndex(
                name: "IX_DriverLocations_CreatedAtUtc",
                table: "DriverLocations",
                column: "CreatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_Deliveries_CompanyId",
                table: "Deliveries",
                column: "CompanyId");

            migrationBuilder.CreateIndex(
                name: "IX_Deliveries_TrackingToken",
                table: "Deliveries",
                column: "TrackingToken",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Associates_CompanyId_AssociateCode",
                table: "Associates",
                columns: new[] { "CompanyId", "AssociateCode" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Associates_CompanyId_BusinessName_Phone",
                table: "Associates",
                columns: new[] { "CompanyId", "BusinessName", "Phone" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Barcodes_CompanyId_Value",
                table: "Barcodes",
                columns: new[] { "CompanyId", "Value" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Barcodes_ProductId_Type",
                table: "Barcodes",
                columns: new[] { "ProductId", "Type" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CashBookEntries_CompanyId_Date_CreatedAtUtc",
                table: "CashBookEntries",
                columns: new[] { "CompanyId", "Date", "CreatedAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_CloudDesigns_CompanyId_BouquetId",
                table: "CloudDesigns",
                columns: new[] { "CompanyId", "BouquetId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ExpenseCategories_CompanyId_Name",
                table: "ExpenseCategories",
                columns: new[] { "CompanyId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MorningPurchaseListItems_CompanyId_ListDate_ProductId",
                table: "MorningPurchaseListItems",
                columns: new[] { "CompanyId", "ListDate", "ProductId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_OccasionContacts_CompanyId_CustomerId_RecipientName_Occasion",
                table: "OccasionContacts",
                columns: new[] { "CompanyId", "CustomerId", "RecipientName", "Occasion" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_OccasionFollowUpActions_CompanyId_SourceType_SourceId_Occur~",
                table: "OccasionFollowUpActions",
                columns: new[] { "CompanyId", "SourceType", "SourceId", "OccurrenceDate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_OpeningCashEntries_CompanyId_Date",
                table: "OpeningCashEntries",
                columns: new[] { "CompanyId", "Date" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ReadyBouquetRecords_CompanyId_FinishedProductId_ProducedAt",
                table: "ReadyBouquetRecords",
                columns: new[] { "CompanyId", "FinishedProductId", "ProducedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ReadyBouquetRefreshEvents_CompanyId_BatchId_CreatedAtUtc",
                table: "ReadyBouquetRefreshEvents",
                columns: new[] { "CompanyId", "BatchId", "CreatedAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_SchedulerRecords_CompanyId_Producer_SourceRef",
                table: "SchedulerRecords",
                columns: new[] { "CompanyId", "Producer", "SourceRef" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WhatsAppAccounts_MemberId",
                table: "WhatsAppAccounts",
                column: "MemberId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WhatsAppAccounts_PhoneNumberId",
                table: "WhatsAppAccounts",
                column: "PhoneNumberId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_DeliveryPerson",
                table: "Orders",
                column: "DeliveryPersonId",
                principalTable: "Staff",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_DeliveryPerson",
                table: "Orders");

            migrationBuilder.DropTable(
                name: "Associates");

            migrationBuilder.DropTable(
                name: "Barcodes");

            migrationBuilder.DropTable(
                name: "CashBookEntries");

            migrationBuilder.DropTable(
                name: "CloudDesigns");

            migrationBuilder.DropTable(
                name: "ExpenseCategories");

            migrationBuilder.DropTable(
                name: "MorningPurchaseListItems");

            migrationBuilder.DropTable(
                name: "OccasionContacts");

            migrationBuilder.DropTable(
                name: "OccasionFollowUpActions");

            migrationBuilder.DropTable(
                name: "OpeningCashEntries");

            migrationBuilder.DropTable(
                name: "ReadyBouquetRecords");

            migrationBuilder.DropTable(
                name: "ReadyBouquetRefreshEvents");

            migrationBuilder.DropTable(
                name: "SchedulerRecords");

            migrationBuilder.DropTable(
                name: "WhatsAppAccounts");

            migrationBuilder.DropIndex(
                name: "IX_StaffAttendanceRecords_CompanyId_StaffId_AttendanceDate",
                table: "StaffAttendanceRecords");

            migrationBuilder.DropIndex(
                name: "IX_Orders_DeliveryPersonId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_DriverLocations_CreatedAtUtc",
                table: "DriverLocations");

            migrationBuilder.DropIndex(
                name: "IX_Deliveries_CompanyId",
                table: "Deliveries");

            migrationBuilder.DropIndex(
                name: "IX_Deliveries_TrackingToken",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "AttendanceDate",
                table: "StaffAttendanceRecords");

            migrationBuilder.DropColumn(
                name: "Notes",
                table: "StaffAttendanceRecords");

            migrationBuilder.DropColumn(
                name: "OvertimeHours",
                table: "StaffAttendanceRecords");

            migrationBuilder.DropColumn(
                name: "RewardPointsEarned",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "RewardPointsRedeemed",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeviceFingerprintHash",
                table: "MobileDevices");

            migrationBuilder.DropColumn(
                name: "DeviceName",
                table: "MobileDevices");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "MobileDevices");

            migrationBuilder.DropColumn(
                name: "ExpenseCategoryId",
                table: "Expenses");

            migrationBuilder.DropColumn(
                name: "PaymentMode",
                table: "Expenses");

            migrationBuilder.DropColumn(
                name: "CompletedAtUtc",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "LastLocationUtc",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "StartedAtUtc",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "AnniversaryMonthDay",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "BirthdayMonthDay",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "CompanyName",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "Department",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "LastOrderAtUtc",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "LastRewardActivityAtUtc",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "LifetimeRewardPoints",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "PendingPaymentAmount",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "RedeemedRewardPoints",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "RewardPoints",
                table: "Customers");

            migrationBuilder.RenameColumn(
                name: "DeliveryLongitude",
                table: "Deliveries",
                newName: "DeliveryAddressLongitude");

            migrationBuilder.RenameColumn(
                name: "DeliveryLatitude",
                table: "Deliveries",
                newName: "DeliveryAddressLatitude");

            migrationBuilder.AlterColumn<string>(
                name: "IncludedModulesJson",
                table: "SubscriptionPlans",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CheckInUtc",
                table: "StaffAttendanceRecords",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldNullable: true);
        }
    }
}
