/*
 * akccap, tool to permit a non-privilaged user to drop capabilities
 * from the bounding set, based on capsh (part of the libcap package)
 * originally by Andrew G. Morgan <morgan@kernel.org>
 *
 * This is a simple wrapper program that can be used to only lower
 * capabilities available to the wrapped program.
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/capability.h>

static const cap_value_t raise_setpcap[1] = { CAP_SETPCAP };

static void push_pcap(cap_t *orig_p, cap_t *raised_for_setpcap_p)
{
    *orig_p = cap_get_proc();
    if (NULL == *orig_p) {
	perror("Capabilities not available");
	exit(1);
    }

    *raised_for_setpcap_p = cap_dup(*orig_p);
    if (NULL == *raised_for_setpcap_p) {
	fprintf(stderr, "modification requires CAP_SETPCAP\n");
	exit(1);
    }
    if (cap_set_flag(*raised_for_setpcap_p, CAP_EFFECTIVE, 1,
		     raise_setpcap, CAP_SET) != 0) {
	perror("unable to select CAP_SETPCAP");
	exit(1);
    }
}

static void pop_pcap(cap_t orig, cap_t raised_for_setpcap)
{
    cap_free(raised_for_setpcap);
    cap_free(orig);
}

static void arg_drop(const char *arg_names)
{
    char *ptr;
    cap_t orig, raised_for_setpcap;
    char *names;

    push_pcap(&orig, &raised_for_setpcap);
    if (strcmp("all", arg_names) == 0) {
	unsigned j = 0;
	while (CAP_IS_SUPPORTED(j)) {
	    int status;
	    if (cap_set_proc(raised_for_setpcap) != 0) {
		perror("unable to raise CAP_SETPCAP for BSET changes");
		exit(1);
	    }
	    status = cap_drop_bound(j);
	    if (cap_set_proc(orig) != 0) {
		perror("unable to lower CAP_SETPCAP post BSET change");
		exit(1);
	    }
	    if (status != 0) {
		char *name_ptr;

		name_ptr = cap_to_name(j);
		fprintf(stderr, "Unable to drop bounding capability [%s]\n",
			name_ptr);
		cap_free(name_ptr);
		exit(1);
	    }
	    j++;
	}
	pop_pcap(orig, raised_for_setpcap);
	return;
    }

    names = strdup(arg_names);
    if (NULL == names) {
	fprintf(stderr, "failed to allocate names\n");
	exit(1);
    }
    for (ptr = names; (ptr = strtok(ptr, ",")); ptr = NULL) {
	/* find name for token */
	cap_value_t cap;
	int status;

	if (cap_from_name(ptr, &cap) != 0) {
	    fprintf(stderr, "capability [%s] is unknown to libcap\n", ptr);
	    exit(1);
	}
	if (cap_set_proc(raised_for_setpcap) != 0) {
	    perror("unable to raise CAP_SETPCAP for BSET changes");
	    exit(1);
	}
	status = cap_drop_bound(cap);
	if (cap_set_proc(orig) != 0) {
	    perror("unable to lower CAP_SETPCAP post BSET change");
	    exit(1);
	}
	if (status != 0) {
	    fprintf(stderr, "failed to drop [%s=%u]\n", ptr, cap);
	    exit(1);
	}
    }
    pop_pcap(orig, raised_for_setpcap);
    free(names);
}

int main(int argc, char *argv[], char *envp[])
{
    unsigned i;

    for (i=1; i<argc; ++i) {
	if (!memcmp("--drop=", argv[i], 4)) {
	    arg_drop(argv[i]+7);
        } else if (!memcmp("--supports=", argv[i], 11)) {
	    cap_value_t cap;

	    if (cap_from_name(argv[i] + 11, &cap) < 0) {
//		fprintf(stderr, "cap[%s] not recognized by library\n",
//			argv[i] + 11);
		exit(11);
	    }
	    if (!CAP_IS_SUPPORTED(cap)) {
//		fprintf(stderr, "cap[%s=%d] not supported by kernel\n",
//			argv[i] + 11, cap);
		exit(12);
	    }
	} else if ((!strcmp("--", argv[i])) ) {
	    argv[i] = strdup(argv[i][0] == '-' ? "/bin/bash" : argv[0]);
	    argv[argc] = NULL;
	    execve(argv[i], argv+i, envp);
	    fprintf(stderr, "execve /bin/bash failed!\n");
	    exit(1);
	}
    }

    exit(0);
}
