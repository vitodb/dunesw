//--------------------------------------------------------------------
//
// SplitterAnalyzer to test SplitterInput source
//
//--------------------------------------------------------------------

#include "art/Framework/Core/EDAnalyzer.h"
#include "art/Framework/Core/ModuleMacros.h"
#include "art/Framework/Principal/Event.h"
#include "art/Utilities/InputTag.h"
#include "fhiclcpp/ParameterSet.h"
#include "messagefacility/MessageLogger/MessageLogger.h"

// lardata
#include "RawData/RawDigit.h"

// C++
#include <cassert>

namespace arttest {

  using rawDigits_t = std::vector<raw::RawDigit>;

  class SplitterAnalyzer : public art::EDAnalyzer {
  public:

    explicit SplitterAnalyzer( fhicl::ParameterSet const& ps) :
      art::EDAnalyzer(ps),
      inputTag_("SplitterInput:TPC"),
      nExpectedEvts_(ps.get<std::size_t>("nExpectedEvents")),
      nEvts_(),
      nExpDigitsLastEvt_(ps.get<std::size_t>("nExpDigitsLastEvent")),
      nExpDigitsPerEvt_(ps.get<std::size_t>("nExpDigitsPerEvent"))
    {}

    virtual ~SplitterAnalyzer(){}

    virtual void analyze( art::Event const & e  ) override {

      ++nEvts_;
      auto rawDigitsH = e.getValidHandle<rawDigits_t>( inputTag_ );
      mf::LogDebug("DigitsTest") << "analyzing event: " << e.id() << " : " << rawDigitsH->size() << " digits present";

      if ( nEvts_ < nExpectedEvts_ ) {
        assert( rawDigitsH->size() == nExpDigitsPerEvt_ );
      }
      else {
        assert( rawDigitsH->size() == nExpDigitsLastEvt_ );
      }

    }

  private:
    art::InputTag inputTag_;
    std::size_t   nExpectedEvts_;
    std::size_t   nEvts_;
    std::size_t   nExpDigitsLastEvt_;
    std::size_t   nExpDigitsPerEvt_;

  };  // SplitterAnalyzer

}

DEFINE_ART_MODULE(arttest::SplitterAnalyzer)
