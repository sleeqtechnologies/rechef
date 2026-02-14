# Rechef: Written Proposal

## Problem Statement

Social media has made recipe discovery effortless. Every day, millions of people save recipe videos on Instagram, TikTok, and YouTube with the intention of cooking them later. But they almost never do.

The problem is not a lack of inspiration. It is everything that happens after. Saved videos get buried under hundreds of other bookmarks. There is no easy way to extract the actual recipe from a video. Figuring out what ingredients you already have versus what you need to buy is a manual chore. And when you finally sit down to cook, fast-paced video instructions assume you are already an experienced cook.

The result: people spend money on takeout instead of cooking the meals they were genuinely excited about. The gap between "I saw this" and "it's on the table" is wide, and nothing on the market closes it end-to-end.

## Target Audience

Rechef is built for anyone who saves recipes but rarely cooks them. Through our research, we identified four core audience segments:

**Busy students and young professionals.** They want to cook more and spend less on takeout but lack the time and structure to follow through. They discover recipes on social media daily but have no system to organize or act on them.

**Home cooks and busy parents.** They cook regularly but waste time hunting for saved recipes, manually writing shopping lists, and juggling multiple apps. They need a streamlined workflow from recipe to table.

**Health-conscious individuals.** They care about what they eat and want visibility into nutritional content. They save healthy recipes frequently but need help turning intention into consistent action.

**Recipe content creators.** They create and share recipes but rely on video descriptions and captions to communicate ingredients and steps. They need a better format to distribute their recipes and a way to track engagement and earn from their content.

Eitan Bernath's brief captures this audience perfectly: people who love food, want to cook, but need the right tool to turn inspiration into action.

## Solution Overview

Rechef is a mobile app that manages the entire journey from saving a recipe to cooking it. The core workflow is:

1. **Save.** Import a recipe from any source (YouTube, TikTok, Instagram, a website, or a photo). Rechef's AI extracts the full recipe, including ingredients, steps, prep time, and servings, into a clean, structured format.

2. **Organize.** Recipes are stored in Cookbooks, which are customizable collections. Smart cookbooks like *Pantry Picks* automatically suggest recipes you can make with ingredients you already have.

3. **Shop.** Each recipe highlights which ingredients are in your Pantry and which are missing. Missing items can be added to a Grocery List with one tap, or purchased directly through Instacart without leaving the app.

4. **Schedule.** Users can set a date and time to cook, and Rechef sends a reminder notification so the recipe does not get forgotten.

5. **Cook.** Cooking Mode provides step-by-step instructions with built-in timers and a real-time AI Cooking Assistant. Users can ask questions by text or voice at any point during the process.

6. **Share.** Any recipe can be shared as a link. Recipients can view, save, and cook the recipe themselves. Creators who share recipes can track views and engagement.

## Monetization Strategy

Rechef uses a freemium subscription model powered by **RevenueCat**.

### Free Tier
- 5 recipe imports per month
- Full access to Cooking Mode, Pantry, Grocery Lists, and Cookbooks
- Recipe sharing

### Rechef Pro (Subscription)
- **Monthly** and **yearly** plans
- Unlimited recipe imports
- AI Cooking Assistant
- Advanced nutrition facts
- Priority processing for recipe extraction

RevenueCat manages all subscription logic, including entitlement checks, paywall presentation, trial management, and the Customer Center for subscription management.

### Additional Revenue: Instacart Referrals
Rechef integrates with Instacart's Connect API, allowing users to purchase grocery list items directly through Instacart. Rechef earns a referral commission (approximately 5%) on each purchase. This creates a usage-based revenue stream that scales with engagement: the more users cook, the more they shop, and the more Rechef earns.

### Future Revenue: Creator Incentive Program
As the platform grows, Rechef plans to introduce a creator incentive program where recipe content creators earn rewards based on the engagement their shared recipes receive (views, saves, cooks). This positions Rechef as a distribution and monetization channel for food influencers, creating a two-sided marketplace.

### Revenue Summary

| Stream | Model | Status |
|---|---|---|
| Rechef Pro Subscription | Monthly / Yearly via RevenueCat | Live |
| Instacart Referral Commission | ~5% per grocery purchase | Live |
| Creator Incentive Program | Revenue share based on engagement | Planned |

## Roadmap

**Immediate (post-hackathon)**
- Collect user feedback and fix remaining bugs
- Submit to the App Store and Google Play
- Improve AI accuracy across more recipe formats and languages

**Short-term (1-3 months)**
- Onboard recipe content creators and import their catalogs
- Launch social media channels promoting recipes via Rechef
- Roll out the creator incentive program

**Long-term (3-12 months)**
- Meal planning with smart suggestions based on pantry, dietary goals, and budget
- Social features: cook-alongs, family recipe books, community cookbooks
- Expand grocery partnerships beyond Instacart to support global markets
- Become the platform where recipes live after discovery, the place where inspiration becomes dinner
