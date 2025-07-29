# RightCode

## Overview

RightCode is a cutting-edge iPad application designed to transform how users practice, verify, and execute handwritten code. Users can effortlessly write code using Apple Pencil, receiving immediate feedback and results. Whether you're a student preparing for coding exams, a developer experimenting with algorithms, or simply someone who enjoys coding by hand, RightCode provides an intuitive, streamlined, and effective coding environment directly on your iPad.

## Motivation

The concept behind RightCode emerged from personal frustration experienced during rigorous exam preparations in software engineering. Frequently, handwritten coding practice lacked immediate verification, causing inefficiencies and stress. RightCode solves this exact issue, combining the familiar and convenient process of handwritten note-taking with real-time digital verification and execution, significantly enhancing productivity and learning.

## Key Features

* **Natural Handwriting Interface:** Utilizing SwiftUI and PencilKit, RightCode ensures a fluid, natural, and responsive handwriting experience.
* **Real-Time Code Execution:** Integrated backend services immediately run handwritten code snippets, providing instant verification of accuracy.
* **Advanced Handwriting Recognition:** Powered by Hugging Face's advanced machine learning model, "nanonets-OCR-s," RightCode delivers highly accurate handwritten text recognition and transcription.
* **Efficient Asynchronous Processing:** Leveraging Redis and Celery, the app handles tasks efficiently, ensuring scalability and high performance.
* **Robust Cloud Infrastructure:** Built with Docker containers and scalable backend services, RightCode is optimized for reliable and fast code execution.

## Technical Details

* **Frontend Technologies:** SwiftUI, PencilKit
* **Backend Technologies:** FastAPI, Python
* **Machine Learning Framework:** Hugging Face's Nanonets-OCR-s
* **Infrastructure & Deployment:** Docker, Redis, Celery

## Use Cases

* **Exam Preparation:** Students benefit from immediate feedback on their handwritten coding exercises.
* **Algorithm Prototyping:** Developers quickly prototype and test algorithms using a comfortable handwriting approach.
* **Educational Tools:** Ideal for instructors teaching coding, allowing real-time demonstration and verification of code.
* **Personal Coding Practice:** Anyone who prefers writing code by hand can now execute and verify their code instantly.
