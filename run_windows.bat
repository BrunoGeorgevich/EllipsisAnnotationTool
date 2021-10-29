echo "REMOVENDO RCC ASSETS ANTIGO"
del main.rcc
echo "GERANDO NOVO RCC ASSETS"
"Tools\rcc.exe" -binary "Frontend\main.qrc" -o main.rcc
echo "EXECUTANDO main.py"
python main.py