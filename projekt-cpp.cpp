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
// #define fileName "example_markers_only_5_corner.bmp"
// #define fileName "example_markers.bmp"
// #define fileName "example_markers_many_5.bmp"
// #define fileName "example_markers_for_tests.bmp"
#define fileName "tttest.bmp"

bool isPixelBlack(char *image, int idx)
{
    return (image[idx] == 0x0 && image[idx + 1] == 0x0 && image[idx + 2] == 0x0);
}

int getLineLength(char *image, int start_idx)
{
    // first pixel must be black
    start_idx += 3;

    // calculate how many iterations left in this line
    int temp = 3 * WIDTH;
    temp -= start_idx % (3 * WIDTH);

    int counter = 1;

    while (temp != 0 && isPixelBlack(image, start_idx))
    {
        counter++;
        temp--;
        start_idx += 3;
    }

    if (temp == 0) // end of line reached
        return 0;
    return counter;
}

bool checkLBlack(char *image, int start_idx, int lengthH, int lengthV)
{
    // mozna zalozyc, ze nie wyjdziemy poza linie obraz

    // checking horizontal line
    int it = start_idx;

    for (int i = lengthH - 1; i >= 0; --i, it += 3)
    {
        if (!isPixelBlack(image, it))
            return false;
    }

    // checking if most right pixel is white
    // it += 3;
    if (isPixelBlack(image, it))
        return false;

    // checking vertical line
    it = start_idx;
    for (int i = lengthV - 1; i >= 0; --i, it -= 3 * WIDTH)
    {
        if (!isPixelBlack(image, it))
            return false;
    }

    // chekcking if the most down pixel is white
    // it -= 3 * WIDTH;
    if (isPixelBlack(image, it))
        return false;

    return true;
}

bool checkLWhite(char *image, int start_idx, int length)
{
    // mozna zalozyc, ze nie wyjdziemy poza linie obraz

    // checking horizontal line

    int it = start_idx;
    for (int i = length + 1; i >= 0; --i, it += 3)
    {
        if (isPixelBlack(image, it))
            return false;
    }
    // checking vertical line
    it = start_idx;
    for (int i = length / 2 + 1; i >= 0; --i, it -= 3 * WIDTH)
    {
        if (isPixelBlack(image, it))
            return false;
    }

    return true;
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

    // reading pixels from array and printing
    //     iteration from left to right,
    // from top to bottom
    for (int i = height - 1; i >= 0; --i)
    {
        std::cout << HEIGHT - i - 1 << " :";
        for (int j = 0; j < width; ++j)
        {
            int idx = i * width + j;
            idx *= 3; // because there
            if (isPixelBlack(image, idx))
                std::cout << "1";
            else
                std::cout << "0";
        }
        std::cout << '\n';
    }

    for (int i = height - 1; i >= 0; --i)
    {
        for (int j = 0; j < width; ++j)
        {
            int idx = i * width + j;
            idx *= 3;

            if (isPixelBlack(image, idx)) // black pixel found
            {
                int l = getLineLength(image, idx);
                if (l == 0) // that means that is the last pixel in a row
                {
                    continue;
                }
                int ah = l;     // a horizontal
                int av = l / 2; // a vertical
                if (checkLWhite(image, idx - 3 + (3 * WIDTH), ah))
                {
                    // std::cout << "white L found obove: "
                    //           << "Column: " << (idx / 3) % width << " Row: " << HEIGHT - ((idx / 3) / width) - 1 << std::endl;
                    while (av != 0 && checkLBlack(image, idx, ah, av))
                    {
                        // std::cout << "Black L found at: "
                        //           << "Column: " << (idx / 3) % width << " Row: " << HEIGHT - ((idx / 3) / width) - 1 << std::endl;
                        idx += (3 * 1) - (3 * WIDTH);
                        ah -= 1;
                        av -= 1;
                    }

                    if (av != 0) // if it is not a rectangle
                    {
                        if (checkLWhite(image, idx, ah))
                        {
                            // std::cout << "!!white L found at: "
                            //           << "Column: " << (idx / 3) % width << " Row: " << HEIGHT - ((idx / 3) / width) - 1 << std::endl;
                            std::cout << "marker found at row: " << height - i - 1 << " column: " << j << std::endl;
                        }
                    }
                }

                j--;
                j += l;
            }
        }
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