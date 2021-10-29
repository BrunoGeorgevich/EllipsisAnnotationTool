export QT_SELECT=qt5
echo "REMOVENDO RCC ASSETS ANTIGO"
rm main.rcc
echo "GERANDO NOVO RCC ASSETS"
rcc -binary "Frontend/main.qrc" -o main.rcc
echo "EXECUTANDO main.py"
python main.py