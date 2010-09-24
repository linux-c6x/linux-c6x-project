#include <stdio.h>
#include <pthread.h>

static pthread_t  HelloWorkerThread;

void HelloWorkerThreadHandler(void * arg)
{
	char *hello_world = (char *)arg;
	int i;

	printf("Hello World Worker thread entered\n"); 
	for (i = 0; i < 10; i++) {
	    printf("spinning in worker thread...\n");
	    sleep(5);
	}
	printf("Hello World Worker thread exiting...\n"); 
}

void main()
{
	int i;
 	printf("Hello World Main thread entered\n");
	if(!pthread_create(&HelloWorkerThread,
			NULL,
			HelloWorkerThreadHandler,
			"Hello Worker Thread\n"))
	{
		printf("Thread created successfully\n");
	} else {
		printf("Error in creating Thread\n");
	}
	
	pthread_join(HelloWorkerThread, NULL);
	for (i = 0; i < 5; i++) {
	    printf("spinning in main thread...\n");
	    sleep(10);
	}
	printf("Hello World Main thread exiting...\n");		
}
