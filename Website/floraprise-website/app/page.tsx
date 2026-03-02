import HeroPremium from "@/components/HeroPremium";
import Features from "@/components/Features";
import FinalCTA from "@/components/FinalCTA";
import CredibilityStrip from "@/components/CredibilityStrip";
import ProblemSection from "@/components/ProblemSection";
import FeatureComparison from "@/components/FeatureComparison";
import Testimonials from "@/components/Testimonials";
import LifestyleSection from "@/components/LifestyleSection";
import DashboardShowcase from "@/components/DashboardShowcase";
import Integrations from "@/components/Integrations";
import ImpactStats from "@/components/ImpactStats";
import Capabilities from "@/components/Capabilities";
import FinalPremiumCTA from "@/components/FinalPremiumCTA";

export default function Home() {
  return (
    <>
      <>
  <HeroPremium />
  <CredibilityStrip />
  <ProblemSection />
  <Features />
  <DashboardShowcase />
  <Integrations />
  <ImpactStats />
  <FeatureComparison />
  <Testimonials />
  <FinalCTA />
</>
    </>
  );
}