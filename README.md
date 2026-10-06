# Управление инфраструктурой проекта с помощью teffaform

Начало работ
```bash
terraform init
terraform validate
terraform plan
terraform apply
```


# TODO:
* Создать тачку `client` под Ubuntu, `postgresql-client-16`
* Прокинуть туда `ssh` ключи своего макбука
* Создать там файл `.pgpass` и `.env` для удобного подключения к хостам
* Создать terraform `MySQL 5.7`
* Настроить тачку client для коннекта в `MySQL 5.7`


# Troubleshooting

### Error: Invalid provider registry host
```bash
Error: Invalid provider registry host
│ 
│ The host "registry.terraform.io" given in provider source address "registry.terraform.io/vk-cs/vkcs" does not offer a Terraform provider registry.
```
Эта ошибка возникает из-за того, что официальный реестр registry.terraform.io заблокировал доступ для пользователей из России


Создайте или откройте конфигурационный файл .terraformrc в вашем домашнем каталоге:
```bash
nano ~/.terraformrc
```

Вставьте в него настройки зеркала (например, от Яндекс.Облака, которое проксирует и зеркалирует официальные провайдеры):
```yml
# ~/.terraformrc
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

После этого попробуйте переинциализировать terraform:
```bash
terraform init

# Terraform has been successfully initialized!

# You may now begin working with Terraform. Try running "terraform plan" to see
# any changes that are required for your infrastructure. All Terraform commands
# should now work.

# If you ever set or change modules or backend configuration for Terraform,
# rerun this command to reinitialize your working directory. If you forget, other
# commands will detect it and remind you to do so if necessary.
```

### Terraform plan: vkcs_db_instance.this must be replaced

Изменение (добавление) `Security Group` в конфигурации terraform приводит к удалению и пересозданию всего инстанса БД.
Эта известная проблема, решения пока нет, ждем правок багов от разработки.


### Terraform apply: Error: error creating vkcs_db_cluster: Internal Server Error

Ошибка может указывать на что угодно. В моем случае был не верно указаны ID сети и подвети в файле `variables.tf`
