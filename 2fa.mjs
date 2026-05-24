import { PrismaClient } from '@prisma/client';
import { authenticator } from 'otplib';

const prisma = new PrismaClient();

try {
  // Fetch all admins
  const admins = await prisma.admin.findMany({ select: { id: true, email: true } });

  if (admins.length === 0) {
    console.log('⚠️  No admin accounts found.');
    process.exit(0);
  }

  console.log(`🔐 Generating unique TOTP secret for each admin...\n`);

  for (const admin of admins) {
    const secret = authenticator.generateSecret(20);
    await prisma.admin.update({
      where: { id: admin.id },
      data: { totpSecret: secret },
    });
    console.log(`✅ ${admin.email}`);
    console.log(`   Secret : ${secret}`);
    console.log(`   QR URI : otpauth://totp/JASMIN:${encodeURIComponent(admin.email)}?secret=${secret}&issuer=JASMIN\n`);
  }

  console.log('✔  Done. Each admin now has their own TOTP secret.');
  console.log('   Scan the QR URI above with Google Authenticator / Authy / 1Password.');
} finally {
  await prisma.$disconnect();
}
