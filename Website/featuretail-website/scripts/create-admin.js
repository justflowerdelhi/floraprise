const bcrypt = require("bcryptjs");
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

async function main() {
  const hashedPassword = await bcrypt.hash("Jfpl@1422", 10);

  const admin = await prisma.user.create({
    data: {
      email: "admin@featuretail.com",
      password: hashedPassword,
      role: "ADMIN",
    },
  });

  console.log("✅ Admin created:", admin.email);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());