NAME    = ft_ping
CC      = cc
CFLAGS  = -Wall -Wextra -g
HDRS    = -I ./includes
LDFLAGS = -lm

OBJ_DIR = objs
OBJS    = $(OBJ_DIR)/main.o

all: $(NAME)

$(NAME): $(OBJS)
	$(CC) $(CFLAGS) $(HDRS) -o $(NAME) $(OBJS) $(LDFLAGS)

$(OBJ_DIR)/main.o: srcs/main.c includes/ft_ping.h
	mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) $(HDRS) -c srcs/main.c -o $(OBJ_DIR)/main.o

clean:
	rm -rf $(OBJ_DIR)

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re