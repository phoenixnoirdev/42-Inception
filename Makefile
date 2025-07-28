# **************************************************************************** #
#                                  VARIABLES                                   #
# **************************************************************************** #

NAME = inception
COMPOSE = docker compose -f srcs/requirements/docker-compose.yml
UID := $(shell id -u)
HOME_PATH := ${HOME}/data

# **************************************************************************** #
#                                 COMMANDS                                     #
# **************************************************************************** #

.PHONY: all setup_dirs setup_secrets up down re clean fclean fcleanall ps logs

all: setup_dirs setup_secrets up

setup_dirs:
	@mkdir -p $(HOME_PATH)/mariadb
	@mkdir -p $(HOME_PATH)/wordpress
	@mkdir -p $(HOME)/secret/mariadb
	@mkdir -p $(HOME)/secret/wordpress

setup_secrets:
	@test -f $(HOME)/secret/mariadb/mysql_user || echo "kevin" > $(HOME)/secret/mariadb/mysql_user
	@test -f $(HOME)/secret/mariadb/mysql_password || echo "test" > $(HOME)/secret/mariadb/mysql_password
	@test -f $(HOME)/secret/mariadb/mysql_root_password || echo "roottest" > $(HOME)/secret/mariadb/mysql_root_password

	@test -f $(HOME)/secret/wordpress/wordpress_user || echo "wp" > $(HOME)/secret/wordpress/wordpress_user
	@test -f $(HOME)/secret/wordpress/wordpress_password || echo "wptest" > $(HOME)/secret/wordpress/wordpress_password
	@test -f $(HOME)/secret/wordpress/wordpress_db_user || echo "kevin" > $(HOME)/secret/wordpress/wordpress_db_user
	@test -f $(HOME)/secret/wordpress/wordpress_db_password || echo "test" > $(HOME)/secret/wordpress/wordpress_db_password

	@chmod 600 $(HOME)/secret/mariadb/*
	@chmod 600 $(HOME)/secret/wordpress/*

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

re: fclean all

clean:
	$(COMPOSE) down --volumes

fclean: clean
	@rm -rf $(HOME)/secret

fcleanall: clean fclean
	sudo rm -rf $(HOME_PATH)/*
	@rm -rf $(HOME_PATH)
ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

