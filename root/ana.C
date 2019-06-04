// This script is used to analyse the unpacked TRB data.
// A: Jose Cuenca
// D: 26.03.2019
// L: 11.04.2019
// ----------------------------------------------------
#include <iostream>
#include <fstream>
#include <vector>
#include "TH1F.h"
#include "TFile.h"
#include "TF1.h"
#include "TVector.h"

using namespace std;

// Methods 
TVector params(TH1F *hist);
Float_t sigma(TH1F *hist);

// Main function with arguments. The input file is specified at the execution of the binary:
// ./anahld file

int main(int argc, char **argv) {
if(argc != 2) { return 1;}
char *filename;

  // Variables
  int nLines=0;
  int tempValue;
  vector<float>data;
  TVector par(4);
  Float_t rms=0.0;
  Int_t channel;
  Float_t signal=0.0;
  Float_t noise=0.0;
  Float_t signalNoise=0.0;
  Float_t sigma2=0.0;
  Float_t std=0.0;

  // Input data file
  filename =  argv[1];
  cout << "Processing data file: " << filename << endl; // check the name of the file

  // Histograms
  TH1F **difHist;
  difHist = new TH1F*[128];
  char title1[250];
    for(Int_t i=0;i<128;i++) {
      sprintf(title1,"%s %i","t_{lead}-t_{trail} (ToT) at channel ",i+1);
      difHist[i] = new TH1F(title1,title1,200,-850,-650);
    }

  TH1F **leadDifHist;
  leadDifHist = new TH1F*[127];
  char title2[250];
    for(Int_t i=0;i<127;i++) {
      sprintf(title2,"%s %i","Difference t_{lead, i+1}-t_{lead,i} at channel ",i+1);
      leadDifHist[i] = new TH1F(title2,title2,40,-20,20);
    }

  // I-O files
  fstream inputFile(filename,std::ios_base::in);

  // Open file and store the line in vector
  nLines = count(istreambuf_iterator<char>(inputFile), istreambuf_iterator<char>(), '\n'); // number of lines of the file
  inputFile.clear(); // go back to the top of the file
  inputFile.seekg(0, ios::beg);

  // Loop in lines
  for(Int_t i=0; i<nLines;i++){
    data.clear();
    for(int j=0;j<256;j++){
      inputFile>> tempValue;
      data.push_back(tempValue); // line content stored in a vector
    }
    
    // Fill histograms using data vector
    for(Int_t m=0; m<128;m++){ difHist[m]->Fill((data[m+128]-data[m]));} // tfall-tlead per channel
    for(Int_t k=0; k<127;k++){ leadDifHist[k]->Fill( (data[k+1]-data[k]) );
    //  if(k<16) leadDifHist[k]->Fill( (data[k+1]-data[k]) );
   //   if(k>=16) leadDifHist[k]->Fill( data[k]-data[27] );
    }
    if(data.size() != 256) cout << "Error: the size of the line " << i << " is not 256 " << endl;

  } // end of the loop in lines

  inputFile.close(); // Close data file
  cout << "Data file closed " << endl;


  // Write parameters to a text file
  ofstream output;
  output.open("params.txt");
  for(int i=0;i<32;i++){
    std=sigma(leadDifHist[i]);
    par=params(difHist[i]);
    channel=i+1;
    signal=par[0];
    noise=par[1];
    signalNoise=par[2];
    sigma2=par[3];
    rms=difHist[i]->GetRMS();
    output <<  channel << "    "  << signal  <<  "    " << noise <<"     "   << signalNoise << "      " << sigma2 <<  "  " << rms << "  " << std << endl;
  }
  output.close();


  // Write histograms to root outputfile *************
  TFile *fOut = new TFile(Form("histos_%s.root",filename),"RECREATE");
  
  for(Int_t i=0;i<128;i++){
    difHist[i]->Write();
  }
  for(Int_t i=0;i<127;i++){
    leadDifHist[i]->Write();
  }

  fOut->Close(); 
  // Close root file *************

cout << "End " << endl;

return 0;

} // end


// ------- params ---------------------
TVector params(TH1F *hist) {
 
  TVector a(4);
  // First fit
  TF1* fun1 = new TF1("fun1name","gaus",hist->GetMean()-2.0*(hist->GetRMS()),hist->GetMean()+2.0*(hist->GetRMS()));
  hist->Fit(fun1,"RQN");

  // Extract mean, sigma, and define limits of the integration
  Float_t mean  = fun1->GetParameter(1);
  Float_t sigma = fun1->GetParameter(2);
  Float_t xInf=mean-1.5*sigma;
  Float_t xSup=mean+1.5*sigma;

  // Second fit
  TF1* fun2 = new TF1("fun2name","gaus",xInf,xSup);
  hist->Fit(fun2,"QR+");

  // Integrate
  Float_t noise=hist->Integral(hist->FindFirstBinAbove(),hist->GetXaxis()->FindBin(xInf))+hist->Integral(hist->GetXaxis()->FindBin(xSup),hist->FindLastBinAbove());	
  Float_t signal=hist->Integral(hist->GetXaxis()->FindBin(xInf),hist->GetXaxis()->FindBin(xSup));	
  Float_t signalNoise=signal/noise;

  a[0] = signal;
  a[1] = noise;
  a[2] = signalNoise;
  a[3] = fun2->GetParameter(2);
  return a;
}
// --------------------------------------
Float_t sigma(TH1F *hist) {
 
  // First fit
  TF1* fun1 = new TF1("fun1name","gaus",hist->GetMean()-4.0*(hist->GetRMS()),hist->GetMean()+4.0*(hist->GetRMS()));
  hist->Fit(fun1,"RQ");

  // Extract mean, sigma, and define limits of the integration
  Float_t sigma = fun1->GetParameter(2);
  
  return sigma;
}
