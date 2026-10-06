terraform {
  required_version = ">= 1.3"

  required_providers {
    vkcs = {
      source  = "vk-cs/vkcs"
      version = "~> 0.10"
    }
  }
}

provider "vkcs" {
  # Учётные данные читаются из переменных окружения OpenStack:
  #   OS_USERNAME, OS_PASSWORD, OS_PROJECT_ID, OS_REGION_NAME, OS_AUTH_URL
  #
  # Для подключения к VK Cloud выполните:
  #   source ./env/bin/activate
  # Будет запрошен пароль пользователя
}
