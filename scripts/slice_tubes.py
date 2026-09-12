from PIL import Image
import numpy as np
import os

def slice_tubes():
    img_path = os.path.join(os.path.dirname(__file__), "..", "assets", "catch-tubes.png")
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "tubes")
    os.makedirs(out_dir, exist_ok=True)
    
    im = Image.open(img_path)
    arr = np.array(im)
    alpha = arr[:, :, 3]
    
    # Identify column intervals where alpha > 20
    col_mask = np.sum(alpha > 20, axis=0) > 10
    
    tubes = []
    in_tube = False
    start_x = 0
    for x in range(len(col_mask)):
        if col_mask[x] and not in_tube:
            in_tube = True
            start_x = x
        elif not col_mask[x] and in_tube:
            in_tube = False
            tubes.append((start_x, x))
    if in_tube:
        tubes.append((start_x, len(col_mask)))
        
    print(f"Detected {len(tubes)} tubes:")
    
    # Mapping based on visual order in catch-tubes.png:
    # Tube 0: Blue (Water - Aqufin)
    # Tube 1: Orange / Brown (Earth - Terron)
    # Tube 2: Red (Fire - Amberfox)
    # Tube 3: White / Silver (Air - Zephyrin)
    # Tube 4: Clear / Empty (Uncaught tube)
    names = [
        "tube_water",
        "tube_earth",
        "tube_fire",
        "tube_air",
        "tube_empty"
    ]
    
    for i, (x1, x2) in enumerate(tubes):
        sub_alpha = alpha[:, x1:x2]
        row_mask = np.sum(sub_alpha > 20, axis=1) > 0
        y_indices = np.where(row_mask)[0]
        y1, y2 = y_indices[0], y_indices[-1]
        
        # Crop tube
        tube_crop = im.crop((x1, y1, x2, y2 + 1))
        tube_name = names[i] if i < len(names) else f"tube_{i}"
        save_path = os.path.join(out_dir, f"{tube_name}.png")
        tube_crop.save(save_path)
        print(f"Saved {tube_name}.png: bbox=({x1}, {y1}, {x2}, {y2+1}), size={tube_crop.size}")

if __name__ == "__main__":
    slice_tubes()
