/**
 * READ-ONLY production verification script for IFA knowledge layer.
 * Run this on the production server: /var/www/floraprise.com/flora
 * Command: npx tsx production_verification.ts
 */

import * as fs from 'fs';
import * as path from 'path';
import { getIfaLeadership, getPresident } from './src/lib/ifa/leadership';
import { getIfaEvents, getNextIfaMeet, getPastIfaMeets, getExhibitionInfo } from './src/lib/ifa/events';
import { getIfaMembershipInfo } from './src/lib/ifa/membership';
import { getIfaGeneralInfo } from './src/lib/ifa/general';
import { searchMembersByPincode, searchMembersByCity, searchMembersByName } from './src/lib/ifa/memberSearch';
import { getNearestFlorists } from './src/lib/floritribeLocator';
import { resolveIfaKnowledge, detectQueryCategory } from './src/lib/ifa/knowledge';

// Load .env.local file manually (dependency-free)
function loadEnvFile() {
  const envPath = path.join(process.cwd(), '.env.local');
  try {
    const envContent = fs.readFileSync(envPath, 'utf-8');
    const lines = envContent.split('\n');
    
    for (const line of lines) {
      const trimmedLine = line.trim();
      // Skip empty lines and comments
      if (!trimmedLine || trimmedLine.startsWith('#')) {
        continue;
      }
      
      // Parse KEY=VALUE or KEY="VALUE" or KEY='VALUE'
      const match = trimmedLine.match(/^([^=]+)=(.*)$/);
      if (match) {
        const key = match[1].trim();
        let value = match[2].trim();
        
        // Remove quotes if present
        if ((value.startsWith('"') && value.endsWith('"')) || 
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.slice(1, -1);
        }
        
        // Set environment variable
        process.env[key] = value;
      }
    }
  } catch (error) {
    // .env.local might not exist or be readable - that's okay
    // The script will use existing environment variables
  }
}

// Load environment variables before importing application modules
loadEnvFile();

async function main() {
  console.log('\n=== IFA KNOWLEDGE LAYER PRODUCTION VERIFICATION ===\n');

  // 1. Leadership
  console.log('1. LEADERSHIP');
  try {
    const leadership = await getIfaLeadership();
    console.log(`Number of leaders: ${leadership.leaders.length}`);
    leadership.leaders.forEach((l: any) => console.log(`- ${l.name}: ${l.role}`));
    console.log(`isStale: ${leadership.isStale}`);
    if (leadership.isStale) {
      console.log(`Data source: CACHED WEBSITE DATA (stale)`);
    } else {
      console.log(`Data source: LIVE WEBSITE DATA`);
    }
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
  }

  // 2. President
  console.log('\n2. PRESIDENT');
  try {
    const president = await getPresident();
    console.log(`President name: ${president.name}`);
    console.log(`isStale: ${president.isStale}`);
    if (president.isStale) {
      console.log(`Data source: CACHED WEBSITE DATA (stale)`);
    } else {
      console.log(`Data source: LIVE WEBSITE DATA`);
    }
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
  }

  // 3. Events
  console.log('\n3. EVENTS');
  try {
    const events = await getIfaEvents();
    console.log(`Number of events: ${events.length}`);
    events.forEach((e: any) => {
      console.log(`- ${e.name}`);
      console.log(`  Date: ${e.date || 'N/A'}`);
      console.log(`  Venue: ${e.venue || 'N/A'}`);
      console.log(`  Registration fee: ${e.registrationFee || 'N/A'}`);
      console.log(`  Registration URL: ${e.registrationUrl || 'N/A'}`);
    });
    if (events.length === 0) {
      console.log(`Data source: NO UPCOMING EVENTS (past events may be available)`);
    } else {
      console.log(`Data source: LIVE WEBSITE DATA`);
    }
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
  }

  console.log('\n4. NEXT IFA MEET');
  try {
    const nextMeet = await getNextIfaMeet();
    console.log(`Next meet: ${nextMeet?.name || 'None'}`);
    if (nextMeet) {
      console.log(`Date: ${nextMeet.date}`);
      console.log(`Venue: ${nextMeet.venue}`);
      console.log(`Data source: LIVE WEBSITE DATA`);
    } else {
      console.log(`Data source: NO UPCOMING EVENTS`);
    }
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
  }

  console.log('\n5. PAST IFA MEETS');
  try {
    const pastMeets = await getPastIfaMeets();
    console.log(`Past meets count: ${pastMeets.length}`);
    pastMeets.forEach((m: any) => console.log(`- ${m.name}: ${m.date}`));
    console.log(`Data source: LIVE WEBSITE DATA (historical)`);
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
  }

  console.log('\n6. EXHIBITION');
  try {
    const exhibition = await getExhibitionInfo();
    if (exhibition) {
      console.log(`Exhibition date: ${exhibition.date}`);
      console.log(`Exhibition venue: ${exhibition.venue}`);
      console.log(`Accommodation: ${exhibition.accommodation}`);
      console.log(`Packages: ${exhibition.packages.length}`);
      exhibition.packages.forEach((p: any) => console.log(`- Type ${p.type}: ${p.price}`));
      console.log(`isStale: ${exhibition.isStale}`);
      if (exhibition.isStale) {
        console.log(`Data source: CACHED WEBSITE DATA (stale)`);
      } else {
        console.log(`Data source: LIVE WEBSITE DATA`);
      }
    } else {
      console.log('No exhibition data');
      console.log(`Data source: NO DATA AVAILABLE`);
    }
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
  }

  // 7. Membership
  console.log('\n7. MEMBERSHIP');
  try {
    const membership = await getIfaMembershipInfo();
    console.log(`Annual fee: ${membership.annualFee}`);
    console.log(`Eligible categories: ${membership.eligibleCategories?.join(', ') || 'N/A'}`);
    console.log(`Benefits: ${membership.benefits?.join(', ') || 'N/A'}`);
    console.log(`Join URL: ${membership.joinUrl}`);
    console.log(`isStale: ${membership.isStale}`);
    if (membership.isStale) {
      console.log(`Data source: CACHED WEBSITE DATA (stale)`);
    } else {
      console.log(`Data source: LIVE WEBSITE DATA`);
    }
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
  }

  // 8. General
  console.log('\n8. GENERAL INFO');
  try {
    const general = await getIfaGeneralInfo();
    console.log(`Founded: ${general.founded}`);
    console.log(`Mission: ${general.mission}`);
    console.log(`Vision: ${general.vision}`);
    console.log(`Description: ${general.description}`);
    console.log(`Contact email: ${general.contactEmail}`);
    console.log(`Contact phone: ${general.contactPhone}`);
    console.log(`Address: ${general.address}`);
    console.log(`Website: ${general.website}`);
    console.log(`isStale: ${general.isStale}`);
    if (general.isStale) {
      console.log(`Data source: CACHED WEBSITE DATA (stale)`);
    } else {
      console.log(`Data source: LIVE WEBSITE DATA`);
    }
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
  }

  // 9. Database member tests
  console.log('\n9. DATABASE MEMBER SEARCH');
  try {
    const pincodeResult = await searchMembersByPincode('110008');
    console.log(`Pincode 110008: ${pincodeResult.members.length} results`);
    pincodeResult.members.slice(0, 3).forEach((m: any) => {
      console.log(`- ${m.businessName}`);
      console.log(`  Address: ${m.address || 'N/A'}`);
      console.log(`  Phone: ${m.phone ? 'Yes' : 'No'}`);
      console.log(`  memberId: ${m.memberId || 'N/A'}`);
    });
    console.log(`Data source: DATABASE DATA`);
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING (DATABASE_URL)`);
  }

  try {
    const cityResult = await searchMembersByCity('Delhi');
    console.log(`City Delhi: ${cityResult.members.length} results`);
    cityResult.members.slice(0, 3).forEach((m: any) => {
      console.log(`- ${m.businessName}`);
      console.log(`  Address: ${m.address || 'N/A'}`);
      console.log(`  Phone: ${m.phone ? 'Yes' : 'No'}`);
      console.log(`  memberId: ${m.memberId || 'N/A'}`);
    });
    console.log(`Data source: DATABASE DATA`);
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING (DATABASE_URL)`);
  }

  try {
    // Use first member from pincode search for name search
    const pincodeResult = await searchMembersByPincode('110008');
    if (pincodeResult.members.length > 0) {
      const nameResult = await searchMembersByName(pincodeResult.members[0].businessName);
      console.log(`Name search for "${pincodeResult.members[0].businessName}": ${nameResult.members.length} results`);
      nameResult.members.slice(0, 3).forEach((m: any) => {
        console.log(`- ${m.businessName}`);
        console.log(`  Address: ${m.address || 'N/A'}`);
        console.log(`  Phone: ${m.phone ? 'Yes' : 'No'}`);
        console.log(`  memberId: ${m.memberId || 'N/A'}`);
      });
      console.log(`Data source: DATABASE DATA`);
    }
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING (DATABASE_URL)`);
  }

  // 10. Floritribe test
  console.log('\n10. FLORITRIBE LOCATION SEARCH');
  try {
    const floritribe = await getNearestFlorists({ city: 'Delhi', pincode: '110008', limit: 3 });
    console.log(`Floritribe results: ${floritribe.length}`);
    floritribe.forEach((f: any) => {
      console.log(`- ${f.name}`);
      console.log(`  Address: ${f.address || 'N/A'}`);
      console.log(`  Phone: ${f.phone ? 'Yes' : 'No'}`);
      console.log(`  memberId: ${f.memberId || 'N/A'}`);
      console.log(`  Distance: ${f.distanceText}`);
    });
    console.log(`Data source: FLORITRIBE DATA`);
  } catch (error: any) {
    console.log(`ERROR: ${error.message}`);
    console.log(`Data source: CONFIGURATION MISSING (FLORITRIBE API)`);
  }

  // 11. Query classification
  console.log('\n11. QUERY CLASSIFICATION');
  const testQueries = [
    "Who is the president of IFA?",
    "Who is the secretary of IFA?",
    "Who are the IFA leaders?",
    "Find florists near 110008",
    "Nearest IFA florist 110008",
    "Give me the contact number of ABC Florist",
    "What is the phone number of ABC Florist?",
    "When is the next IFA Meet?",
    "Where was IFA Meet 8 held?",
    "How much is IFA membership?",
    "How can I join IFA?",
    "What is IFA?",
  ];

  testQueries.forEach(query => {
    const category = detectQueryCategory(query);
    console.log(`"${query}" -> ${category}`);
  });
  console.log(`Data source: LOCAL CLASSIFICATION LOGIC`);

  // 12. Direct knowledge resolution
  console.log('\n12. DIRECT KNOWLEDGE RESOLUTION');
  for (const query of testQueries) {
    try {
      const result = await resolveIfaKnowledge({ text: query });
      console.log(`\nQuery: "${query}"`);
      console.log(`Category: ${result.category}`);
      console.log(`Source: ${result.source}`);
      if (result.source === 'website') {
        console.log(`Data source: LIVE WEBSITE DATA`);
      } else if (result.source === 'database') {
        console.log(`Data source: DATABASE DATA`);
      } else if (result.source === 'floritribe') {
        console.log(`Data source: FLORITRIBE DATA`);
      } else if (result.source === 'session') {
        console.log(`Data source: SESSION STATE DATA`);
      } else {
        console.log(`Data source: FALLBACK DATA OR NO DATA`);
      }
      console.log(`Knowledge preview: ${result.text.substring(0, 500)}...`);
    } catch (error: any) {
      console.log(`\nQuery: "${query}" -> ERROR: ${error.message}`);
      console.log(`Data source: CONFIGURATION MISSING OR ERROR`);
    }
  }

  // 13. Date handling verification
  console.log('\n13. DATE HANDLING VERIFICATION');
  const currentDate = new Date();
  console.log(`Current server date: ${currentDate.toISOString()}`);
  const eventDate = new Date('2026-08-18');
  console.log(`IFA Meet 8 date: 2026-08-18`);
  console.log(`IFA Meet 8 is past: ${eventDate < currentDate}`);
  console.log(`Data source: LOCAL DATE COMPARISON LOGIC`);

  // 14. Source behavior summary
  console.log('\n14. SOURCE BEHAVIOR SUMMARY');
  console.log('Leadership: Check isStale flag above (LIVE WEBSITE vs CACHED)');
  console.log('Events: Check if events returned (LIVE WEBSITE vs NO UPCOMING)');
  console.log('Membership: Check isStale flag above (LIVE WEBSITE vs CACHED)');
  console.log('General: Check isStale flag above (LIVE WEBSITE vs CACHED)');
  console.log('Database: Check if DATABASE_URL is configured');
  console.log('Floritribe: Check if FLORITRIBE API is configured');
  console.log('Classification: Always LOCAL LOGIC');
  console.log('Date handling: Always LOCAL LOGIC');
  console.log('\nLEGEND:');
  console.log('- LIVE WEBSITE DATA: Fresh data from official IFA website');
  console.log('- CACHED WEBSITE DATA: Stale cached data from official IFA website');
  console.log('- DATABASE DATA: Data from business_profiles database');
  console.log('- FLORITRIBE DATA: Data from Floritribe location API');
  console.log('- SESSION STATE DATA: Data from conversation session state');
  console.log('- FALLBACK DATA: Hardcoded fallback values when no data available');
  console.log('- CONFIGURATION MISSING: Environment variable not set');

  console.log('\n=== VERIFICATION COMPLETE ===\n');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
