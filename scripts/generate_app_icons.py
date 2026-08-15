"""
Generate app launcher icons for both Flutter apps.
Creates PNG icons at all required Android densities.
User app: indigo-violet gradient with truck icon
Partner app: teal gradient with bike icon
"""
import os
from PIL import Image, ImageDraw

def create_gradient_bg(size, colors):
    """Create a diagonal gradient background."""
    img_final = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw_final = ImageDraw.Draw(img_final)
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            r = int(colors[0][0] * (1 - t) + colors[1][0] * t)
            g = int(colors[0][1] * (1 - t) + colors[1][1] * t)
            b = int(colors[0][2] * (1 - t) + colors[1][2] * t)
            draw_final.point((x, y), fill=(r, g, b, 255))
    return img_final

def draw_truck(draw, size, color):
    """Draw a simple truck/van icon centered on the image."""
    cx, cy = size // 2, size // 2
    s = size // 3
    x1, y1 = cx - s, cy - s // 2
    x2, y2 = cx + s // 2, cy + s // 2
    draw.rounded_rectangle([x1, y1, x2, y2], radius=max(2, s // 6), fill=color)
    cx2 = cx + s // 2
    draw.rounded_rectangle([cx2, cy - s // 4, cx2 + s // 3, cy + s // 2], radius=max(2, s // 8), fill=color)
    draw.rounded_rectangle([cx2 + s // 12, cy - s // 6, cx2 + s // 4, cy], radius=2, fill=(255, 255, 255, 200))
    wheel_r = max(3, s // 6)
    draw.ellipse([cx - s // 2, cy + s // 3, cx - s // 2 + wheel_r * 2, cy + s // 3 + wheel_r * 2], fill=color)
    draw.ellipse([cx + s // 4, cy + s // 3, cx + s // 4 + wheel_r * 2, cy + s // 3 + wheel_r * 2], fill=color)

def draw_bike(draw, size, color):
    """Draw a simple motorcycle icon centered on the image."""
    cx, cy = size // 2, size // 2
    s = size // 3
    wheel_r = max(3, s // 3)
    lx = cx - s // 2
    ly = cy + s // 4
    draw.ellipse([lx - wheel_r, ly - wheel_r, lx + wheel_r, ly + wheel_r], outline=color, width=max(2, s // 8))
    rx = cx + s // 2
    ry = cy + s // 4
    draw.ellipse([rx - wheel_r, ry - wheel_r, rx + wheel_r, ry + wheel_r], outline=color, width=max(2, s // 8))
    draw.ellipse([lx - wheel_r // 3, ly - wheel_r // 3, lx + wheel_r // 3, ly + wheel_r // 3], fill=color)
    draw.ellipse([rx - wheel_r // 3, ry - wheel_r // 3, rx + wheel_r // 3, ry + wheel_r // 3], fill=color)
    draw.line([(lx, ly), (cx, cy - s // 4), (rx, ry)], fill=color, width=max(2, s // 6))
    draw.rounded_rectangle([cx - s // 6, cy - s // 3, cx + s // 4, cy - s // 6], radius=max(2, s // 12), fill=color)

def generate_icon(colors, icon_drawer, base_path):
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, size in sizes.items():
        dir_path = os.path.join(base_path, 'android', 'app', 'src', 'main', 'res', folder)
        os.makedirs(dir_path, exist_ok=True)
        img = create_gradient_bg(size, colors)
        draw = ImageDraw.Draw(img)
        mask = Image.new('L', (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, size, size], radius=max(2, size // 5), fill=255)
        img.putalpha(mask)
        icon_color = (255, 255, 255, 255)
        if icon_drawer == 'truck':
            draw_truck(draw, size, icon_color)
        elif icon_drawer == 'bike':
            draw_bike(draw, size, icon_color)
        out_path = os.path.join(dir_path, 'ic_launcher.png')
        img.save(out_path, 'PNG')
        print(f"  {folder}/ic_launcher.png ({size}x{size})")
        img.save(os.path.join(dir_path, 'ic_launcher_round.png'), 'PNG')

    web_path = os.path.join(base_path, 'assets', 'images')
    os.makedirs(web_path, exist_ok=True)
    img = create_gradient_bg(512, colors)
    draw = ImageDraw.Draw(img)
    mask = Image.new('L', (512, 512), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, 512, 512], radius=100, fill=255)
    img.putalpha(mask)
    if icon_drawer == 'truck':
        draw_truck(draw, 512, (255, 255, 255, 255))
    elif icon_drawer == 'bike':
        draw_bike(draw, 512, (255, 255, 255, 255))
    img.save(os.path.join(web_path, 'app_logo.png'), 'PNG')
    print(f"  assets/images/app_logo.png (512x512)")

base = '/home/z/my-project/delivery-platform/apps'

print("=== Generating USER APP icons (indigo-violet gradient + truck) ===")
generate_icon([(99, 102, 241), (139, 92, 246)], 'truck', os.path.join(base, 'user_app'))

print("\n=== Generating PARTNER APP icons (teal gradient + bike) ===")
generate_icon([(15, 118, 110), (20, 184, 166)], 'bike', os.path.join(base, 'partner_app'))

print("\n✓ All launcher icons generated!")
