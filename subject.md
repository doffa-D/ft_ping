# ft_ping — Subject

> **Summary:** This project is about recoding the ping command.
> **Version:** 5.1

---

## Chapter I — Foreword

Ettore Majorana (born on 5 August 1906 – possibly dying after 1959) was an Italian theoretical physicist. He is best known for his work in particle physics, with particular applications of neutrino theory. His sudden and mysterious loss, in the spring of 1938, gave rise to many speculations on a possible suicide in the Tyrrhenian Sea, or on a voluntary disappearance.

> *"There are several categories of scientists in the world; those of second or third rank do their best but never get very far. Then there is the first rank, those who make important discoveries, fundamental to scientific progress. But then there are the geniuses, like Galilei and Newton. Majorana was one of these."*

---

## Chapter II — Introduction

Ping is the name of a command that allows you to test the accessibility of another machine through the IP network. The command also measures the time taken to receive a response, called the **round-trip time**.

---

## Chapter III — General Instructions

- Your project must be realized in a **virtual machine running on Debian (>= 7.0)**.
- Your virtual machine must have all the necessary software to complete your project. These softwares must be configured and installed.
- You must be able to use your virtual machine from a cluster computer.
- This project will be corrected by humans only. You're allowed to organise and name your files as you see fit, but you must follow the following rules.
- You must use **C** and submit a **Makefile**.
- Your Makefile must compile the project and must contain the usual rules. It must recompile and re-link the program only if necessary.
- You have to handle errors carefully. In no way can your program quit in an unexpected manner (Segmentation fault, bus error, double free, etc).
- You are authorised to use the libc functions to complete this project.

> ⚠️ **ATTENTION:** Program in C, all libC is authorised. **Using the system ping or the sources of a standard ping in any way is forbidden.**

---

## Chapter IV — Mandatory Part

- The executable must be named **`ft_ping`**.
- You will take as reference the ping implementation from **inetutils-2.0** (`ping -V`).
- You have to manage the **`-v`** and **`-?`** options.

> ⚠️ The `-v` option here will also allow us to see the results in case of a problem or an error linked to the packets, which logically shouldn't force the program to stop (the modification of the TTL value can help to force an error).

- You will have to manage a simple **IPv4 (address/hostname)** as parameters.
- You will have to manage **FQDN** without doing the DNS resolution in the packet return.

> 💡 You are allowed to use all the functions of the printf family.

> ⚠️ For the smarty pants (or not)... Obviously you are **NOT** allowed to call a real ping.

---

## Chapter V — Bonus Part

Find below a few ideas of interesting bonuses:

- Additional flags: **`-f` `-l` `-n` `-w` `-W` `-p` `-r` `-s` `-T` `--ttl` `--ip-timestamp`**

> 💡 The flags `-V`, `--usage`, `--echo` are **not** considered as bonus.

> 💡 Of course two flags corresponding to the same feature (e.g. `-t` and `--type`) are **not** considered as two bonuses.

> ⚠️ The bonus part will only be assessed if the mandatory part is **PERFECT**. Perfect means the mandatory part has been integrally done and works without malfunctioning. If you have not passed ALL the mandatory requirements, your bonus part will not be evaluated at all.

---

## Chapter VI — Submission and Peer-Evaluation

Turn in your assignment in your Git repository as usual. Only the work inside your repository will be evaluated during the defense.

- You have to be in a **VM with a Linux kernel > 3.14**. Note that grading was designed on a Debian 7.0 stable.
- Except for the RTT line and the reverse DNS resolution, the result must have an **indentation identical to the implementation from inetutils-2.0**.

> 💡 A delay of **+/- 30ms** is tolerated on the reception of a packet.