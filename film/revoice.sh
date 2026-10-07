#!/bin/bash
# Rehace las voces con ElevenLabs y vuelve a montar la película sin re-renderizar imagen ni música.
# Necesita: ELEVENLABS_API_KEY en el entorno y acceso de red a api.elevenlabs.io
set -e
cd "$(dirname "$0")"
command -v sox >/dev/null || (apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sox libsox-fmt-mp3 fonts-ebgaramond)
fc-list | grep -qi "EB Garamond" || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq fonts-ebgaramond
python3 -c "import numpy, scipy, soundfile" 2>/dev/null || pip install -q numpy scipy soundfile
python3 audio/tts_eleven.py "$@"     # voces -> build/voice/*.wav
python3 audio/mix.py                 # diálogo nuevo + música/ambiente guardados en kit/
python3 assemble.py --ass            # subtítulos con los tiempos nuevos
python3 assemble.py --kit            # imagen limpia del kit + subtítulos + mezcla -> ../TODA_LA_LUZ.mp4
echo "Listo: TODA_LA_LUZ.mp4"
