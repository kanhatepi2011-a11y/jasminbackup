import { NextResponse } from "next/server";

function notFoundResponse() {
  return NextResponse.json(
    { error: "Not found" },
    {
      status: 404,
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
      },
    }
  );
}

export async function GET() {
  return notFoundResponse();
}

export async function POST() {
  return notFoundResponse();
}

export async function PUT() {
  return notFoundResponse();
}

export async function PATCH() {
  return notFoundResponse();
}

export async function DELETE() {
  return notFoundResponse();
}
