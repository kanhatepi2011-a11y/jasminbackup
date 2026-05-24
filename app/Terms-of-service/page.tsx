import Link from "next/link";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import type { Metadata } from "next";
import type { ReactNode } from "react";

export const metadata: Metadata = {
  title: "ការមិនទទួលខុសត្រូវក្រោយការទិញរួច | JASMIN TOPUP",
  description:
    "គោលការណ៍ស្តីពីការមិនទទួលខុសត្រូវ ការសងប្រាក់ និងការកែប្រែបញ្ជាទិញក្រោយពេលទិញ Package នៅ JASMIN TOPUP។",
  keywords: [
    "jasmin topup",
    "policy",
    "refund",
    "terms",
    "UID",
    "Cambodia",
    "game top up",
  ],
  openGraph: {
    title: "ការមិនទទួលខុសត្រូវក្រោយការទិញរួច | JASMIN TOPUP",
    description:
      "គោលការណ៍ស្តីពីការមិនទទួលខុសត្រូវ ការសងប្រាក់ និងការកែប្រែបញ្ជាទិញក្រោយពេលទិញ Package នៅ JASMIN TOPUP។",
    type: "website",
  },
};

// ─── Reusable components ───────────────────────────────────────────────────────

function SectionCard({
  icon,
  title,
  children,
  accent = false,
}: {
  icon: string;
  title: string;
  children: ReactNode;
  accent?: boolean;
}) {
  return (
    <div
      className={`rounded-2xl p-6 shadow-md border ${
        accent
          ? "bg-gradient-to-br from-pink-50 to-rose-50 border-pink-200"
          : "bg-white border-gray-100"
      }`}
    >
      <div className="flex items-center gap-3 mb-4">
        <span className="text-2xl">{icon}</span>
        <h2 className="text-lg font-bold text-gray-800 leading-snug">
          {title}
        </h2>
      </div>

      <div className="text-gray-700 text-sm leading-relaxed space-y-2">
        {children}
      </div>
    </div>
  );
}

function BulletItem({ icon, text }: { icon: string; text: string }) {
  return (
    <li className="flex items-start gap-2">
      <span className="mt-0.5 text-base shrink-0">{icon}</span>
      <span>{text}</span>
    </li>
  );
}

// ─── Page ──────────────────────────────────────────────────────────────────────

export default function TermsOfServicePage() {
  return (
    <>
      <Header />

      <main className="min-h-screen bg-gradient-to-br from-pink-50 via-rose-50 to-white">
        <div className="max-w-3xl mx-auto px-4 py-10 space-y-6">
          {/* Hero header */}
          <div className="text-center space-y-2 pb-2">
            <div className="inline-flex items-center gap-2 bg-pink-100 text-pink-600 text-xs font-semibold px-3 py-1 rounded-full">
              📋 Policy
            </div>

            <h1 className="text-2xl sm:text-3xl font-extrabold text-gray-900 leading-snug">
              ការមិនទទួលខុសត្រូវ
              <br />
              <span className="text-pink-500">ក្រោយការទិញរួច</span>
            </h1>

            <p className="text-gray-500 text-sm">
              កែប្រែចុងក្រោយ: ២៤ ឧសភា ២០២៦
            </p>
          </div>

          {/* Warning card */}
          <div className="rounded-2xl border-2 border-amber-300 bg-gradient-to-r from-amber-50 to-yellow-50 p-5 shadow-md">
            <div className="flex gap-3">
              <span className="text-3xl shrink-0">⚠️</span>

              <div>
                <p className="font-bold text-amber-800 text-base mb-1">
                  សូមអានឱ្យបានយ៉ាងដិតដល់មុនបញ្ជាទិញ
                </p>

                <p className="text-amber-700 text-sm leading-relaxed">
                  សូមអតិថិជនពិនិត្យព័ត៌មានឱ្យបានត្រឹមត្រូវមុនពេលបញ្ជាទិញ។
                  បន្ទាប់ពីការបញ្ជាទិញត្រូវបានបង់ប្រាក់
                  និងបានបញ្ចប់/ដឹកជញ្ជូនរួច{" "}
                  <strong>JASMIN TOPUP</strong>{" "}
                  មិនទទួលខុសត្រូវចំពោះកំហុសដែលកើតឡើងពីការបញ្ចូលព័ត៌មានខុសរបស់អតិថិជនឡើយ។
                </p>
              </div>
            </div>
          </div>

          {/* Section 1 */}
          <SectionCard
            icon="🚫"
            title="ករណីដែល JASMIN TOPUP មិនទទួលខុសត្រូវ"
            accent
          >
            <p className="text-gray-600 mb-3">
              ការបញ្ជាទិញណាដែលបានបញ្ចប់/ដឹកជញ្ជូនរួច
              JASMIN TOPUP មិនទទួលខុសត្រូវក្នុងករណីខាងក្រោម៖
            </p>

            <ul className="space-y-2">
              <BulletItem icon="❌" text="បញ្ចូល UID / Player ID ខុស" />
              <BulletItem icon="❌" text="ជ្រើសរើស Server / Region ខុស" />
              <BulletItem icon="❌" text="ជ្រើសរើស Game ឬ Package ខុស" />
              <BulletItem
                icon="❌"
                text="បញ្ជាទិញទៅកាន់គណនីអ្នកផ្សេងដោយចៃដន្យ"
              />
              <BulletItem
                icon="❌"
                text="បង់ប្រាក់រួច ប៉ុន្តែចង់ប្តូរ Package ក្រោយមក"
              />
              <BulletItem
                icon="❌"
                text="ករណី Account របស់អតិថិជនមានបញ្ហាដែលមិនពាក់ព័ន្ធនឹង JASMIN TOPUP"
              />
              <BulletItem
                icon="❌"
                text="ករណី Game provider / third-party service មានការផ្លាស់ប្តូរ ឬពន្យារពេល"
              />
            </ul>
          </SectionCard>

          {/* Section 2 */}
          <SectionCard
            icon="💳"
            title="គោលការណ៍សងប្រាក់ / លុបចោលការបញ្ជាទិញ"
          >
            <div className="bg-red-50 border border-red-200 rounded-xl p-4 mb-3">
              <p className="font-semibold text-red-700 text-sm">
                🔒 ការបញ្ជាទិញដែលបានដឹកជញ្ជូនរួច មិនអាចសងប្រាក់
                ឬលុបចោលបានឡើយ។
              </p>
            </div>

            <p>
              ប្រសិនបើការបញ្ជាទិញ<strong> មិនទាន់ </strong>
              ដំណើរការ អតិថិជនអាចទាក់ទង Support ភ្លាមៗ
              ដើម្បីស្នើសុំជំនួយ ប៉ុន្តែ
              <strong> មិនធានា</strong>ថាអាចកែប្រែបានទេ។
            </p>

            <p className="text-gray-500 text-xs mt-2">
              💡 ដើម្បីបង្ការបញ្ហា សូមផ្ទៀងផ្ទាត់ UID និង Server
              ជាមុនពេលបង់ប្រាក់។
            </p>
          </SectionCard>

          {/* Section 3 */}
          <SectionCard icon="✅" title="ទំនួលខុសត្រូវរបស់អតិថិជន" accent>
            <p className="mb-3">
              អតិថិជនត្រូវតែធ្វើការពិនិត្យដូចខាងក្រោមមុនពេលបញ្ជាទិញ
              ដើម្បីជៀសវាងកំហុស៖
            </p>

            <ul className="space-y-2">
              <BulletItem icon="✔️" text="ពិនិត្យ UID / Player ID ឱ្យបានច្បាស់" />
              <BulletItem
                icon="✔️"
                text="ពិនិត្យ Server / Region ឱ្យបានត្រឹមត្រូវ"
              />
              <BulletItem
                icon="✔️"
                text="ពិនិត្យឈ្មោះ Game និង Package ដែលចង់បាន"
              />
              <BulletItem
                icon="✔️"
                text="រក្សា receipt / order number សម្រាប់ជាភស្តុតាង"
              />
              <BulletItem
                icon="✔️"
                text="ទាក់ទង Support ភ្លាមៗ ប្រសិនបើមានកំហុសសង្ស័យ"
              />
            </ul>
          </SectionCard>

          {/* Section 4 — Support CTA */}
          <div className="rounded-2xl bg-gradient-to-br from-pink-500 to-rose-500 p-6 shadow-lg text-white">
            <div className="flex items-center gap-3 mb-3">
              <span className="text-2xl">🤝</span>
              <h2 className="text-lg font-bold">យើងនៅទីនេះដើម្បីជួយអ្នក</h2>
            </div>

            <p className="text-pink-100 text-sm leading-relaxed">
              យើងនឹងព្យាយាមជួយអតិថិជនតាមដែលអាចធ្វើបាន។
              ប្រសិនបើកំហុសកើតចេញពី
              <strong className="text-white"> ប្រព័ន្ធរបស់ JASMIN TOPUP</strong>{" "}
              ឬការដឹកជញ្ជូន<strong className="text-white"> មិន</strong>បានបញ្ចប់
              យើងនឹងពិនិត្យ និងដោះស្រាយដោយ
              <strong className="text-white"> យុត្តិធម៌</strong>។
            </p>

            <div className="mt-4 pt-4 border-t border-pink-400/50 flex flex-wrap gap-3 text-sm">
              <a
                href="https://t.me/jasmintopup"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 bg-white/20 hover:bg-white/30 transition-colors rounded-full px-4 py-1.5 font-semibold"
              >
                📱 Telegram Support
              </a>

              <a
                href="https://t.me/thephal"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 bg-white/20 hover:bg-white/30 transition-colors rounded-full px-4 py-1.5 font-semibold"
              >
                💬 @thephal
              </a>
            </div>
          </div>

          {/* Section 5 — Quick reminder */}
          <div className="rounded-2xl border border-blue-200 bg-blue-50 p-5">
            <div className="flex gap-3">
              <span className="text-2xl shrink-0">💡</span>

              <div>
                <p className="font-bold text-blue-800 text-sm mb-1">
                  ចំណាំសំខាន់
                </p>

                <ul className="text-blue-700 text-sm space-y-1 list-disc list-inside">
                  <li>
                    ការបញ្ជាទិញដែលបានបញ្ចប់{" "}
                    <strong>មិន</strong>អាចត្រឡប់ក្រោយបានទេ
                  </li>
                  <li>
                    ករណីបញ្ហាពី <strong>JASMIN TOPUP</strong> —
                    យើងទទួលខុសត្រូវ ១០០%
                  </li>
                  <li>
                    ករណីកំហុសរបស់អតិថិជន — JASMIN TOPUP{" "}
                    <strong>មិន</strong>ទទួលខុសត្រូវ
                  </li>
                  <li>ទំនាក់ទំនងជំនួយ ២៤/៧ តាម Telegram</li>
                </ul>
              </div>
            </div>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-3 pt-2 pb-6">
            <Link
              href="/"
              className="flex-1 text-center bg-gradient-to-r from-pink-500 to-rose-500 text-white font-bold py-3.5 rounded-2xl shadow-md hover:shadow-lg hover:from-pink-600 hover:to-rose-600 transition-all text-sm"
            >
              🏠 ត្រឡប់ទៅទំព័រដើម
            </Link>

            <Link
              href="/order"
              className="flex-1 text-center bg-white border-2 border-pink-400 text-pink-600 font-bold py-3.5 rounded-2xl shadow-sm hover:bg-pink-50 transition-all text-sm"
            >
              📦 តាមដានការបញ្ជាទិញ
            </Link>
          </div>
        </div>
      </main>

      <Footer />
    </>
  );
}