import json
from pathlib import Path

# 📁 Directory containing individual .summary.json files
input_dir = Path("/ruta/a/tu/carpeta")  # 👈 Reemplazá por la ruta real
output_file = input_dir / "full_summary.json"

# 🧠 Límite de caracteres totales que la AI puede aceptar
max_chars = 380000
char_count = 0
combined_summary = []

# 🔁 Procesar cada archivo .summary.json
for file in input_dir.glob("*.summary.json"):
    try:
        with open(file, "r") as f:
            summary_data = json.load(f)

        for item in summary_data:
            item_text = json.dumps(item)
            item_len = len(item_text)

            # ⛔ Si agregar este item se pasa del límite, nos detenemos
            if char_count + item_len > max_chars:
                print(f"⚠️ Limit reached at file {file.name}")
                break

            combined_summary.append(item)
            char_count += item_len

    except Exception as e:
        print(f"❌ Failed to process {file.name}: {e}")

# 💾 Guardar el archivo combinado
with open(output_file, "w") as f:
    json.dump(combined_summary, f, indent=2)

print(f"✅ Combined summary saved as: {output_file.name}")
print(f"🧮 Total characters: {char_count}")
