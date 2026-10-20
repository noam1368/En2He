---
name: check-computer
description: Score a computer the user is considering buying (a Yad2 ad, store listing, or spec list) from 0-100 for running deep-learning models locally on an NVIDIA GPU, within a budget of about 5,000 ILS. Use when the user pastes a computer ad or specs and asks what you think, whether it fits, or to check it.
---

# check-computer

The user wants to run DL models locally (LLMs, image generation, small fine-tunes) and has about **5,000 ILS** in total. Reply in the user's language (usually Hebrew).

## Background

- **Current machine:** Dynabook Satellite Pro L50-G-181 laptop. i7-10510U (4C/8T, up to 4.9 GHz, 15W), 16 GB DDR4 (2 of 2 slots used, 2x8), integrated Intel UHD, Samsung 970 EVO Plus 2 TB NVMe. One USB-C port, 5 Gbps, no Thunderbolt. So it cannot take an internal or external GPU.
- **Recommended plan:** a used desktop tower (up to about 2,000 ILS) plus a new RTX 5060 Ti 16GB (about 3,000 ILS). The card draws about 180W, needs one 8-pin PCIe connector and runs on PCIe x8.
- **Cheaper fallback:** RTX 3060 12GB (about 1,600 ILS).
- **GPU vendor:** stick with NVIDIA, since CUDA is the standard and AMD on Windows is a pain for DL.
- **VRAM guide:** 8 GB is too little; 12 GB fits LLMs up to about 8B at 4-bit; 16 GB fits about 14B at 4-bit, SDXL/Flux, and QLoRA on 7-8B; 24 GB fits larger LLMs.

## Steps

1. **Identify the machine.** Pull out every spec stated in the listing. If a model name is given (e.g. "HP ProBook 440" with i5-10210U → G7), use WebSearch to fill in missing facts: ports, Thunderbolt, PSU, slots, form factor. Mark each fact as "stated in the ad" or "from model specs". Never invent a spec; unknown stays unknown.
2. **Apply the gates.** A gate caps the score no matter what else is good.
   - Laptop or all-in-one without an NVIDIA GPU of at least 8 GB VRAM: **cap 15**. Such a machine has no upgrade path.
   - Laptop with an NVIDIA GPU: score it on that GPU's VRAM. Laptop VRAM is fixed and can't be upgraded, so **cap 60**.
   - Brand office desktop (Dell OptiPlex, HP EliteDesk/ProDesk, Lenovo ThinkCentre), SFF/mini/tiny, or a proprietary PSU with no 8-pin PCIe: **cap 30**.
   - Total cost (price + any GPU still needed, about 3,000 for a 5060 Ti 16GB) above 6,000 ILS: **cap 40**.
3. **Score the criteria (100 points).**

   | Criterion | Pts | Full marks | Partial |
   |---|---|---|---|
   | GPU | 35 | Already has an NVIDIA GPU with 16 GB+ VRAM, or a tower with a free PCIe x16 slot ready for one | 12 GB NVIDIA: 25. Tower with GPU slot but no GPU: 20 (the purchase is still needed). 8 GB NVIDIA: 15 (still upgradable in a tower). |
   | PSU | 15 | Standard ATX, 550W+, known brand, has an 8-pin PCIe connector | Unknown wattage or brand: 7. Under 450W or no 8-pin: 0-3 |
   | Price vs. budget | 15 | Price + GPU still needed ≤ 5,000 ILS | ≤ 5,500: 10. ≤ 6,000: 5 |
   | CPU | 10 | Intel 12th gen+ or Ryzen 5000+ desktop | Intel 10-11th gen or Ryzen 3000: 7. Older: 3 |
   | RAM | 10 | 32 GB+ | 16 GB with free slots: 7. 16 GB, slots full: 5. 8 GB: 2 |
   | Motherboard / PCIe | 5 | PCIe 4.0+ x16 (B550/X570, Intel 12th gen+, or 11th gen on B560/Z590) | PCIe 3.0: 3. Unknown: 2 |
   | Storage | 5 | 1 TB+ SSD | 500 GB SSD: 3. Under 500 GB or HDD only: 1 |
   | Case | 5 | Mid/full tower with room for a 25-30 cm card | Unknown: 2. Small/SFF: 0 |

   Score unknown items at the "unknown" level, or about half marks if no such level is listed, and say so.
4. **Compare to the current laptop.** In one line: is this a real step up for DL, or a sidegrade?
5. **Record and compare.** Read `candidates.md` (next to this file). Add the new listing, or update an existing one when the user brings new details such as price, city or answers from the seller. Record the date, city, price, full parts list, score, notes and open questions. Then compare it with the other candidates.

## Output format

- **Score: NN/100**: one-line verdict (buy / worth checking / skip).
- **Table:** criterion, what the listing says, points.
- **Gates hit:** if any, and why.
- **Total cost:** listing price + GPU still needed (if no price is given, say so).
- **Missing info:** questions to ask the seller (PSU wattage and brand, 8-pin connector, motherboard model, case size, GPU model and VRAM).
- **Sources:** links to any web pages used.

Don't repeat personal details from the ad (phone numbers, names, emails).
