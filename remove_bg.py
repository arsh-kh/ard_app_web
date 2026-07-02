import sys
from PIL import Image

def remove_black_background(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()
    
    newData = []
    for item in datas:
        # Check if the pixel is black or very dark
        if item[0] < 20 and item[1] < 20 and item[2] < 20:
            newData.append((0, 0, 0, 0)) # Transparent
        else:
            newData.append(item)
            
    img.putdata(newData)
    img.save(output_path, "PNG")
    print(f"Saved {output_path}")

if __name__ == "__main__":
    remove_black_background('assets/images/baker.jpeg', 'assets/images/baker.png')
