void readpars(){

  // Variables
  Int_t nLines;
  Float_t rms=0.0;
  Int_t channel=0;
  Float_t signal=0.0;
  Float_t noise=0.0;
  Float_t signalNoise=0.0;
  Float_t sigma2=0.0;
  Float_t std=0.0;

  // I-O files
  fstream inputFile("params.txt",std::ios_base::in);

  // Open file and store the line in vector
  nLines = count(istreambuf_iterator<char>(inputFile), istreambuf_iterator<char>(), '\n'); // number of lines of the file
  inputFile.clear(); // go back to the top of the file
  inputFile.seekg(0, ios::beg);

  Double_t ch[nLines], sg[nLines], ns[nLines], sn[nLines], s2[nLines], rm[nLines], dif[nLines], resT[nLines];
  // Loop in lines
  for(Int_t i=0; i<nLines;i++){
      inputFile >> channel >> signal  >> noise >> signalNoise >> sigma2 >> rms >> std;
      ch[i] = channel;
      sg[i] = signal;
      ns[i] = noise;
      sn[i] = signalNoise;
      s2[i] = sigma2*100.0; // 1 bin = 100 ps
      rm[i] = rms*100.0;
      dif[i] = (rms-sigma2)*100.0;
      resT[i] = std*100.0/TMath::Sqrt(2.0);
    }
  inputFile.close();

  TCanvas *c1 = new TCanvas("c1","Sigmas",200,10,700,500);
  TGraph *gr = new TGraph(nLines,ch,sn);
  gr->Draw("AC*");

  /*TCanvas *c2 = new TCanvas("c2","Dif Sigmas",200,10,700,500);
  TGraph *gr2 = new TGraph(nLines,ch,dif);
  gr->Draw("AC*");

  TCanvas *c3 = new TCanvas("c3","Time resolution",200,10,700,500);
  TGraph *gr3 = new TGraph(nLines,ch,resT);
  gr3->Draw("AC*");*/
}
