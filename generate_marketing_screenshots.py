import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1080, 1920

screens_data = [
    {
        'src': r'C:\Users\nagas\.gemini\antigravity\brain\30a7828e-64c5-4841-a328-5ff236a440e1\.user_uploaded\media_1791820785486.jpg',
        'badge': 'AI-POWERED RESUME BUILDER',
        'badge_color': (99, 102, 241),  # Indigo
        'title': 'Build ATS-Ready Resumes',
        'subtitle': 'Craft high-impact professional resumes optimized for recruiters in minutes.',
        'out': '01_pro_dashboard.png',
        'glow_color': (99, 102, 241),
    },
    {
        'src': r'C:\Users\nagas\.gemini\antigravity\brain\30a7828e-64c5-4841-a328-5ff236a440e1\.user_uploaded\media_1791820785483.jpg',
        'badge': 'REAL-TIME ATS SCORING',
        'badge_color': (244, 63, 94),  # Rose
        'title': 'Instant ATS Radar & Score',
        'subtitle': 'Detect keyword gaps, impact verbs, and formatting before applying.',
        'out': '02_pro_ats_radar.png',
        'glow_color': (244, 63, 94),
    },
    {
        'src': r'C:\Users\nagas\.gemini\antigravity\brain\30a7828e-64c5-4841-a328-5ff236a440e1\.user_uploaded\media_1791820785481.jpg',
        'badge': 'SMART AI ENHANCER',
        'badge_color': (168, 85, 247),  # Purple
        'title': 'Fix Everything with 1-Tap AI',
        'subtitle': 'Transform weak bullet points with action verbs & quantitative metrics.',
        'out': '03_pro_ai_recommendations.png',
        'glow_color': (168, 85, 247),
    },
    {
        'src': r'C:\Users\nagas\.gemini\antigravity\brain\30a7828e-64c5-4841-a328-5ff236a440e1\.user_uploaded\media_1791820785477.jpg',
        'badge': 'RECRUITER-TESTED TEMPLATES',
        'badge_color': (16, 185, 129),  # Emerald
        'title': 'Curated ATS Templates',
        'subtitle': 'Executive, Modern Classic & Tech layouts built to pass ATS scanners.',
        'out': '04_pro_templates.png',
        'glow_color': (16, 185, 129),
    },
]

out_dir = r'C:\Users\nagas\Documents\PROJECTS\Resume Brain\play_store_assets\screenshots_marketing_pro_9_16'
os.makedirs(out_dir, exist_ok=True)

font_bold_path = r'C:\Windows\Fonts\segoeuib.ttf'
font_semi_path = r'C:\Windows\Fonts\segoeui.ttf'

font_badge = ImageFont.truetype(font_bold_path, 24)
font_title = ImageFont.truetype(font_bold_path, 56)
font_sub = ImageFont.truetype(font_semi_path, 28)

for item in screens_data:
    # 1. Base gradient
    canvas = Image.new('RGBA', (W, H), (7, 9, 14, 255))
    grad = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(grad)
    for y in range(H):
        ratio = y / H
        r = int(7 + ratio * 8)
        g = int(9 + ratio * 14)
        b = int(14 + ratio * 28)
        grad_draw.line([(0, y), (W, y)], fill=(r, g, b, 255))
    canvas = Image.alpha_composite(canvas, grad)

    # 2. Ambient Glow Sphere
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    gx, gy = W // 2, 850
    gr = 420
    gc = item['glow_color']
    for rad in range(gr, 0, -8):
        alpha = int(((1.0 - rad / gr) ** 2) * 75)
        glow_draw.ellipse([gx - rad, gy - rad, gx + rad, gy + rad], fill=(gc[0], gc[1], gc[2], alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=50))
    canvas = Image.alpha_composite(canvas, glow)

    draw = ImageDraw.Draw(canvas)

    # 3. Badge Pill
    badge_text = item['badge']
    bw = draw.textlength(badge_text, font=font_badge)
    pill_w = bw + 44
    pill_h = 46
    pill_x = (W - pill_w) / 2
    pill_y = 75

    pill_bg = (item['badge_color'][0], item['badge_color'][1], item['badge_color'][2], 45)
    pill_border = (item['badge_color'][0], item['badge_color'][1], item['badge_color'][2], 200)

    pill_img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(pill_img)
    pdraw.rounded_rectangle([pill_x, pill_y, pill_x + pill_w, pill_y + pill_h], radius=23, fill=pill_bg, outline=pill_border, width=2)
    pdraw.text((pill_x + 22, pill_y + 8), badge_text, font=font_badge, fill=(255, 255, 255, 245))
    canvas = Image.alpha_composite(canvas, pill_img)
    draw = ImageDraw.Draw(canvas)

    # Title
    title_text = item['title']
    tw = draw.textlength(title_text, font=font_title)
    draw.text(((W - tw) / 2, 145), title_text, font=font_title, fill=(255, 255, 255, 255))

    # Subtitle
    sub_text = item['subtitle']
    sw = draw.textlength(sub_text, font=font_sub)
    draw.text(((W - sw) / 2, 222), sub_text, font=font_sub, fill=(156, 163, 175, 255))

    # 4. Device Chassis & Screenshot
    raw_img = Image.open(item['src']).convert('RGBA')
    w_raw, h_raw = raw_img.size
    # Crop status bar (44px) and bottom pill (20px)
    cropped_screen = raw_img.crop((0, 44, w_raw, h_raw - 20))

    phone_w = 750
    phone_h = int(phone_w * (cropped_screen.height / cropped_screen.width))
    screen_resized = cropped_screen.resize((phone_w, phone_h), Image.Resampling.LANCZOS)

    mask_radius = 44
    mask = Image.new('L', (phone_w, phone_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, phone_w, phone_h], radius=mask_radius, fill=255)

    border_thick = 10
    device_total_w = phone_w + (border_thick * 2)
    device_total_h = phone_h + (border_thick * 2)

    device_x = (W - device_total_w) // 2
    device_y = 310

    # Shadow
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [device_x + 10, device_y + 20, device_x + device_total_w - 10, device_y + device_total_h + 30],
        radius=mask_radius + 6,
        fill=(0, 0, 0, 190)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=30))
    canvas = Image.alpha_composite(canvas, shadow)

    # Frame Bezel
    chassis = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(chassis)
    cdraw.rounded_rectangle(
        [device_x, device_y, device_x + device_total_w, device_y + device_total_h],
        radius=mask_radius + border_thick,
        fill=(24, 29, 44, 255),
        outline=(55, 65, 81, 255),
        width=2
    )
    canvas = Image.alpha_composite(canvas, chassis)
    canvas.paste(screen_resized, (device_x + border_thick, device_y + border_thick), mask)

    # Save
    final_rgb = canvas.convert('RGB')
    out_path = os.path.join(out_dir, item['out'])
    final_rgb.save(out_path, 'PNG', optimize=True)
    size_kb = os.path.getsize(out_path) / 1024
    print(f"Generated {item['out']} ({size_kb:.1f} KB)")
