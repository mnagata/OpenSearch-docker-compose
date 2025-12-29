import uvicorn
from fastapi import FastAPI
from fastapi.responses import FileResponse

app = FastAPI()


@app.get("/")
def home():
    return {"message": "model download url App"}


@app.get("/get_file/model/{filename:path}")
async def get_file(filename: str):
    """モデルファイルのダウンロード"""

    file_path = "/model/" + filename

    response = FileResponse(path=file_path, filename=filename)

    return response


if __name__ == "__main__":
    uvicorn.run("app:app", host="127.0.0.1", port=8000, reload=True)
