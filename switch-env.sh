#!/bin/bash

# Configuración de variables
RESOURCE_GROUP="rg-phoenix-prod-001"
AGW_NAME="agw-phoenix-prod"
RULE_NAME="rule-http-routing"

if [ -z "$1" ]; then
    echo "❌ Uso incorrecto."
    echo "Debes especificar el entorno de destino."
    echo "Ejemplo: ./switch-env.sh blue  O  ./switch-env.sh green"
    exit 1
fi

TARGET_COLOR=$(echo "$1" | tr '[:upper:]' '[:lower:]')

if [ "$TARGET_COLOR" == "blue" ]; then
    POOL_NAME="pool-blue"
elif [ "$TARGET_COLOR" == "green" ]; then
    POOL_NAME="pool-green"
else
    echo "❌ Entorno no válido. Usa 'blue' o 'green'."
    exit 1
fi

echo "🔍 Obteniendo la dirección IP pública del Application Gateway..."
APP_IP=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "pip-agw-phoenix-prod" \
  --query "ipAddress" -o tsv)

if [ -z "$APP_IP" ]; then
    echo "❌ No se pudo obtener la IP pública del Application Gateway."
    exit 1
fi

echo "🌐 IP del servicio detectada: http://$APP_IP"
echo "🔄 Preparando conmutación hacia el entorno: ${TARGET_COLOR^^} ($POOL_NAME)..."

# 1. Actualizar el Application Gateway
az network application-gateway rule update \
  --resource-group "$RESOURCE_GROUP" \
  --gateway-name "$AGW_NAME" \
  --name "$RULE_NAME" \
  --address-pool "$POOL_NAME" \
  --output none

if [ $? -eq 0 ]; then
    echo "⏳ Regla actualizada. Esperando estabilización del balanceador y ejecutando Smoke Test..."
    sleep 5

    # 2. Smoke Testing: Verificar respuesta HTTP del endpoint /health o raíz
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$APP_IP/")

    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "✅ ¡Smoke Test exitoso! El servicio responde con HTTP 200."
        echo "🚀 ¡Cambio de tráfico completado con éxito! El entorno ${TARGET_COLOR^^} está operando en producción."
    else
        echo "⚠️ Advertencia: El Application Gateway actualizó la regla, pero el endpoint respondió con código HTTP: $HTTP_STATUS"
        echo "🔍 Verifica el estado de las instancias del VMSS correspondiente."
    fi
else
    echo "❌ Error crítico al actualizar el Application Gateway."
    exit 1
fi
