using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ObjectDetection;
using System.Drawing;


namespace ConsoleApplication1
{
    class Program
    {
        static void Main(string[] args)
        {
            
            string ImagePath = "Scale Cross Section.bmp";
            Bitmap MyBitMap = new Bitmap(ImagePath);

            //Byte[] UpperRegion = {255, 100, 100};
            //Byte[] LowerRegion = { 150, 0, 0 };

            Byte[,,] RawDataMatrix = new Byte[MyBitMap.Height, MyBitMap.Width, 3];

            for (int iRow = 0; iRow < MyBitMap.Height; iRow++)
            {
                for (int jCol = 0; jCol < MyBitMap.Width; jCol++)
                {
                    Color MyColor = MyBitMap.GetPixel(jCol, iRow);
                    RawDataMatrix[iRow, jCol, 0] = MyColor.R;
                    RawDataMatrix[iRow, jCol, 1] = MyColor.G;
                    RawDataMatrix[iRow, jCol, 2] = MyColor.B;
                }
            }

           bool[,] BW_Image = new bool[MyBitMap.Height, MyBitMap.Width];
           int Height = MyBitMap.Height;
            Parallel.For(0, MyBitMap.Width, jCol =>
                {
                    Byte[] UpperRegion = {255, 100, 100};
                    Byte[] LowerRegion = { 150, 0, 0 };
                    for (int iRow = 0; iRow < Height; iRow++)
                    {
                        for (int iColor = 0; iColor < 2; iColor++)
                        {
                            if (RawDataMatrix[iRow,jCol,iColor] >= LowerRegion[iColor] && 
                                    RawDataMatrix[iRow,jCol,iColor] <= UpperRegion[iColor]
                                )
                            {
                                BW_Image[iRow, jCol] = true;
                            }
                            else
                            {
                                BW_Image[iRow, jCol] = false;
                            }
                        }
                    }
                });

            BlobFinder myBlobFinder = new BlobFinder();
            myBlobFinder.BW = BW_Image;
            myBlobFinder.Get_1D_Blobs();
            myBlobFinder.MatchBlobs();
            myBlobFinder.Assign_Blobs();
            DateTime before = DateTime.Now;
            myBlobFinder.FixBlobs();
            DateTime after = DateTime.Now;
            myBlobFinder.ConsolidateBlobs();
            Bitmap NewImage = new Bitmap(MyBitMap);
            for (int i = 0; i < NewImage.Height; i++)
            {
                for (int j = 0; j < NewImage.Width; j++)
                {
                    if (myBlobFinder.AssignedBlob[i, j] != 0)
                    {
                        int Rem;
                        Math.DivRem(myBlobFinder.AssignedBlob[i, j], 4, out Rem);
                        if (Rem == 0)
                            NewImage.SetPixel(j, i, Color.FromArgb(0, 0, 0));
                        else if (Rem == 1)
                            NewImage.SetPixel(j, i, Color.FromArgb(255, 0, 0));
                        else if (Rem == 2)
                            NewImage.SetPixel(j, i, Color.FromArgb(0, 255, 0));
                        else if (Rem == 3)
                            NewImage.SetPixel(j, i, Color.FromArgb(0, 0, 255));
                    }
                    else 
                    {
                        NewImage.SetPixel(j, i, Color.FromArgb(255, 255, 255));
                    }
                       
                }
            }
            NewImage.Save("TempData.bmp");
            
            TimeSpan TimeElapsed = after.Subtract(before);
            double Time = ((double)TimeElapsed.TotalMilliseconds) / 1000;
            Console.WriteLine("Time Elapsed: {0} sec",Time);
            Console.WriteLine("Press Any Key to Continue...");
            Console.ReadLine();
        }
        
    }
}
