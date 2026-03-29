# ft_ping — Evaluation Sheet

---

## Introduction

We ask you for the good progress of this evaluation to respect the following rules:

- Be courteous, polite, respectful and constructive in all situations during this exchange.
- Highlight to the person (or group) noted the possible malfunctions of work done, and take the time to discuss.
- Accept that there may sometimes be differences of interpretation on the subject's requests or the scope of the features. Stay open-minded and write down as honestly as possible.

---

## Guidelines

- You should only evaluate what is on the student/group's rendering Git repository.
- Make sure that the Git repository is the one corresponding to the student or group and the project.
- Meticulously verify that no malicious alias has been used to mislead you.
- Any meaningful script facilitating the evaluation provided by one of the two parties must be rigorously checked by the other party.
- If the correcting student has not yet done this project, it is mandatory to read the subject in full before starting this defense.
- Use the flags available on this scale to signal an empty rendering, non-functional, a standard fault, a cheat case, etc. In this case, the evaluation is completed and the final grade is **0** (or **-42** in the special case of cheating).

> ⚠️ **The evaluation must take place in a Linux virtual machine with a kernel > 3.14 with root rights.**

---

## ft_ping base — Preliminaries

Before starting the defense, please check the following points:

- [ ] The project is in **C**
- [ ] The project uses only the **authorized functions** (fcntl, poll and ppoll are **not** used)
- [ ] Only **one global** is used
- [ ] A **Makefile** containing the usual rules is present

> ⚠️ If only one of these points is invalid, the correction stops.

---

## Checking Arguments

The program checks if the user has the necessary rights and runs correctly with the `-h` option. It displays a simple, clear and fair explanation of its use.

- [ ] **Yes**
- [ ] **No**

---

## ft_ping ip

> For all questions in the scale, you will compare the standard output with the ping system command via a **diff**. A difference of **+/- 30ms** is acceptable on a package. The DNS resolution, in the return of the packet, of the tested address is **not mandatory**. The last line (concerning the RTT) will be **ignored**. The program will be stopped via **CTRL + C**.

### ft_ping good ip

Start the program with a valid and functional IPv4 address parameter.

Does the program work the same as the system ping?
*(Reminder: a difference of +/- 30ms is acceptable on a package.)*

- [ ] **Yes**
- [ ] **No**

---

### ft_ping bad ip

Start the program with a valid and non-functional IPv4 address parameter.

Does the program work the same as the system ping?

- [ ] **Yes**
- [ ] **No**

---

### ft_ping -v bad ip

Run the program with the `-v` option on a valid and non-functional IPv4 address.

The supporter must clearly explain the return of the display of his program.

- [ ] **Yes**
- [ ] **No**

---

## ft_ping hostname

### ft_ping good hostname

Start the program with as parameter a valid and functional hostname.

Does the program work the same as the system ping?

- [ ] **Yes**
- [ ] **No**

---

### ft_ping bad hostname

Run the program with a valid non-functional hostname parameter.

Does the program work the same as the system ping?

- [ ] **Yes**
- [ ] **No**

---

### ft_ping -v bad hostname

Run the program with the `-v` option on a valid and non-functional IPv4 address.

> The TTL value should be changed here.

The supporter must clearly explain the return of the display of his program.

- [ ] **Yes**
- [ ] **No**

---

## ft_ping bonus

> Bonuses are counted **only if ALL previous points are valid**.

You can count up to **5 separate bonuses** for this project.

> ⚠️ The `-V` flag is **not** a welcome bonus.

**Rate it from 0 (failed) through 5 (excellent):** `_____ / 5`

---

## Ratings

Check the appropriate flag:

| Flag | Description |
|---|---|
| ✅ Okay | Project works correctly |
| ⭐ Outstanding project | Exceptional work |
| 📄 Empty work | Nothing submitted |
| 📋 Incomplete work | Partially done |
| 👤 No author file | Missing login/author file |
| ❌ Invalid compilation | Does not compile |
| 📏 Standard | Norm errors |
| 🚫 Cheat | Cheating detected (-42) |
| 💥 Crash | Program crashes |
| 🔒 Forbidden function | Used unauthorized functions |

---

## Conclusion

Leave a comment on this evaluation:

> _______________________________________________