#include <iostream>
#include <vector>
#include <fstream>
#include <cstddef>

#define HEIGHT 240
#define WIDTH 320

#define WIDTH_OFFSET 0x12       // there is width stored
#define HEIGHT_OFFSET 0x16      // there is height stored
#define FIRST_PIXEL_OFFSET 0x0A // there is the information, where pixels start
#define HEADER_SIZE 54          // how many bytes are in theheader

#define N 100000
#define fileName "example_markers.bmp"

bool isPixelBlack()
{
    return false;
}

void readBMP()
{
    std::ifstream reader;
    reader.open(fileName, std::ios::binary);
    if (reader.good())
        std::cout << "Otwarto plik...\n";
    else
    {
        std::cout << "Unable to open file\n";
        return;
    }

    // read header
    char header[HEADER_SIZE];
    reader.read(header, HEADER_SIZE);

    auto fileSize = *reinterpret_cast<uint32_t *>(&header[2]);
    auto dataOffset = *reinterpret_cast<uint32_t *>(&header[10]);
    auto width = *reinterpret_cast<uint32_t *>(&header[18]);
    auto height = *reinterpret_cast<uint32_t *>(&header[22]);
    auto depth = *reinterpret_cast<uint16_t *>(&header[28]);

    uint32_t numberOfPixels = width * height;

    std::cout << "fileSize: " << fileSize << std::endl;
    std::cout << "dataOffset: " << dataOffset << std::endl;
    std::cout << "width: " << width << std::endl;
    std::cout << "height: " << height << std::endl;
    std::cout << "number of pixels: " << numberOfPixels << std::endl;
    std::cout << "depth: " << depth << "-bit" << std::endl;

    // skipping additinal information, by moving pointer on the list
    reader.seekg(dataOffset);

    // reading image to list
    char image[3 * numberOfPixels];
    reader.read(image, 3 * numberOfPixels);

    // reading pixels
    char c;
    for (int i = height - 1; i >= 0; --i)
    {
        for (int j = 0; j < width; ++j)
        {
            int idx = i * width + j;
            idx *= 3; // because there
            // std::cout << *reinterpret_cast<uint32_t *>(&header[idx]) << std::endl;
            if (image[idx] == 0x0 && image[idx + 1] == 0x0 && image[idx + 2] == 0x0)
                std::cout << "1";
            else
                std::cout << "0";
        }
        std::cout << '\n';
    }

    reader.close();
}

int main()
{
    /*
        specification:

        sub format: 24 bit RGB – no compression,
        size: width 320px, height 240 px,
        76800 pixeli
    */

    // 1. load everything to buffor
    readBMP();
}