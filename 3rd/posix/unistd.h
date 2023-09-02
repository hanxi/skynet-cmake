#pragma once

#include <assert.h>
#include <stdio.h>
#include <time.h>
#include <process.h>
#include <io.h>
#include <assert.h>
#include <stdlib.h>

#define ssize_t size_t

#define random rand
#define srandom srand
#define snprintf _snprintf
#define localtime_r _localtime64_s

#define pid_t int

int kill(pid_t pid, int exit_code);

void usleep(size_t us);
void sleep(size_t ms);

enum { CLOCK_THREAD_CPUTIME_ID, CLOCK_REALTIME, CLOCK_MONOTONIC };
int clock_gettime(int what, struct timespec *ti);

enum { LOCK_EX, LOCK_NB };
int flock(int fd, int flag);

struct sigaction {
  void (*sa_handler)(int);
  int sa_flags;
  int sa_mask;
};
enum { SIGPIPE, SIGHUP, SA_RESTART };
void sigfillset(int *flag);
int sigemptyset(int* set);
void sigaction(int flag, struct sigaction *action, void* param);

int pipe(int fd[2]);
int daemon(int a, int b);

#define O_NONBLOCK 1
#define F_SETFL 0
#define F_GETFL 1

int fcntl(int fd, int cmd, long arg);

char *strsep(char **stringp, const char *delim);

int write(int fd, const void* ptr, unsigned int sz);
int read(int fd, void* buffer, unsigned int sz);
int close(int fd);

#define getpid _getpid
#define open _open
#define dup2 _dup2
