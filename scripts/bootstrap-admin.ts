#!/usr/bin/env node
import dotenv from 'dotenv';

import prisma from '../src/utils/prisma.js';
import { createUser } from '../src/services/userService.js';

dotenv.config();

const args = process.argv.slice(2);

const getArg = (flag: string) => {
  const index = args.indexOf(flag);
  if (index === -1) return undefined;
  return args[index + 1];
};

const tenantSlug = getArg('--tenant-slug');
const email = getArg('--email');
const password = getArg('--password');
const name = getArg('--name') ?? 'Tenant Admin';

if (!tenantSlug || !email || !password) {
  // eslint-disable-next-line no-console
  console.error('Usage: npm run bootstrap:admin -- --tenant-slug <slug> --email <email> --password <password> [--name <displayName>]');
  process.exit(1);
}

const main = async () => {
  const tenant = await prisma.tenant.findUnique({ where: { slug: tenantSlug } });
  if (!tenant) {
    throw new Error(`Tenant with slug ${tenantSlug} not found. Create the tenant first.`);
  }

  await createUser({
    email,
    password,
    displayName: name,
    roles: ['admin'],
    tenantId: tenant.id,
  });

  // eslint-disable-next-line no-console
  console.log(`Admin user ${email} bootstrapped for tenant ${tenant.slug}.`);
};

main()
  .catch((error) => {
    // eslint-disable-next-line no-console
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
