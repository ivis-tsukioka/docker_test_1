FROM cschranz/gpu-jupyter:v1.4_cuda-11.2_ubuntu-20.04_python-only

# install netbase
USER root
#pubkeyの更新(22/6/16)
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub

RUN apt-get update -y
RUN apt-get install -y netbase
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# mamba installを使いたかったがdatalad pushに失敗するため
# conda installを利用している（2/2時点）
RUN conda install --quiet --yes git-annex==8.20210903
RUN conda install --quiet --yes git==2.35.0
RUN conda install --quiet --yes datalad==0.15.4
RUN conda clean -i -t -y

# install the notebook package etc.
RUN python -m pip install --no-cache-dir --upgrade pip
RUN python -m pip install --no-cache-dir --upgrade setuptools
RUN python -m pip install --no-cache-dir notebook
RUN python -m pip install --no-cache-dir jupyter_contrib_nbextensions
RUN python -m pip install --no-cache-dir git+https://github.com/NII-cloud-operation/Jupyter-LC_run_through
RUN python -m pip install --no-cache-dir git+https://github.com/NII-cloud-operation/Jupyter-multi_outputs
RUN python -m pip install --no-cache-dir datalad==0.15.4
RUN python -m pip install --no-cache-dir lxml==4.7.1
RUN python -m pip install --no-cache-dir blockdiag==3.0.0
RUN python -m pip install --no-cache-dir -U nbformat==5.2.0
RUN python -m pip install --no-cache-dir papermill==2.3.3
RUN python -m pip install --no-cache-dir black==21.12b0

RUN jupyter contrib nbextension install --user
RUN jupyter nbextensions_configurator enable --user
RUN jupyter run-through quick-setup --user
RUN jupyter nbextension install --py lc_multi_outputs --user
RUN jupyter nbextension enable --py lc_multi_outputs --user

# install Japanese-font (for blockdiag)
ARG font_deb=fonts-ipafont-gothic_00303-18ubuntu1_all.deb
RUN mkdir ${HOME}/.fonts
RUN wget -P ${HOME}/.fonts http://archive.ubuntu.com/ubuntu/pool/universe/f/fonts-ipafont/${font_deb}
RUN dpkg-deb -x ${HOME}/.fonts/${font_deb} ~/.fonts
RUN cp ~/.fonts/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf ~/.fonts/ipag.ttf
RUN rm ${HOME}/.fonts/${font_deb}
RUN rm -rf ${HOME}/.fonts/etc ${HOME}/.fonts/usr
RUN rm .wget-hsts

ARG NB_USER=jovyan
ARG NB_UID=1000

RUN rm -rf ${HOME}/work

# prepare datalad procedure dir
RUN mkdir -p ${HOME}/.config/datalad/procedures

WORKDIR ${HOME}
COPY . ${HOME}

USER root
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}

# Specify the default command to run
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
