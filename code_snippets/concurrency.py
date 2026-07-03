import concurrent.futures
import time


def task(n):
    print(f"executing task {n}")
    time.sleep(n)
    return f"Task {n} completed"


# using thread pool executor
def main():
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        results = [executor.submit(task, i) for i in range(1, 4)]
    for future in concurrent.futures.as_completed(results):
        print(future.result())


def better_task(n):
    if n == 2:
        raise ValueError("Task2 is faulty")
    print(f"executing task {n}")
    time.sleep(n)
    return f"Task {n} completed"


def better_main():
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        results = [executor.submit(better_task, i) for i in range(1, 4)]
    for future in concurrent.futures.as_completed(results):
        try:
            print(future.result())
        except Exception as e:
            print(f"A task failed with exception {str(e)}")
