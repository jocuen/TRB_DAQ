void drawHistos(){

  // Open root file
  TFile *file = new TFile("histos_Mini1.dat.root");

  // Create array with the histograms
  TH1F *h[128];

  // Name of the histograms to be attached
  char name[200];

  // Get histograms and fill the array
  for(int j=0;j<128;j++){
   sprintf(name, "%s_%i","Difference of times at channel",j+1);
   h[j] = (TH1F*)file->Get(name);
 }

  // Create canvases and fill them
  TCanvas *c1 = new TCanvas("c1","Channels 1 to 32");
  c1->Divide(8,4);
  TCanvas *c2 = new TCanvas("c2","Channels 32 to 64");
  c2->Divide(8,4);
  TCanvas *c3 = new TCanvas("c3","Channels 64 to 96");
  c3->Divide(8,4);
  TCanvas *c4 = new TCanvas("c4","Channels 96 to 128");
  c4->Divide(8,4);

  for(Int_t i=0;i<32;i++){
  c1->cd(i+1);
  h[i]->Draw();
  }
  for(Int_t i=32;i<64;i++){
  c2->cd(i-31);
  h[i]->Draw();
  }
  for(Int_t i=64;i<96;i++){
  c3->cd(i-63);
  h[i]->Draw();
  }
  for(Int_t i=96;i<128;i++){
  c4->cd(i-95);
  h[i]->Draw();
  }

 
 } 


