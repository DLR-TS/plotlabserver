/********************************************************************************
 * Copyright (C) 2017-2020 German Aerospace Center (DLR).
 * Eclipse ADORe, Automated Driving Open Research https://eclipse.org/adore
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Contributors:
 *   Daniel Heß - initial API and implementation
 ********************************************************************************/

#include <plotlabserver/plotlab.h>

namespace DLR {
namespace PlotLab {
TriStrip::TriStrip(double *x, double *y, unsigned int size) {
  this->size = size;
  double minx = 9e6, miny = 9e6, minz = 9e6, maxx = -9e6, maxy = -9e6,
         maxz = -9e6;
  // values = new double[size*3];
  for (unsigned int i = 0; i < size && i * 3 + 2 < PlotObject::BUFFER_SIZE;
       i++) {
    values[i * 3] = x[i];
    values[i * 3 + 1] = y[i];
    values[i * 3 + 2] = 0;
    minx = std::min(minx, (double)(x[i]));
    miny = std::min(miny, (double)(y[i]));
    minz = std::min(minz, 0.0);
    maxx = std::max(maxx, (double)(x[i]));
    maxy = std::max(maxy, (double)(y[i]));
    maxz = std::max(maxz, 0.0);
  }
  setBoundMax(maxx, maxy, maxz);
  setBoundMin(minx, miny, minz);
}
TriStrip::TriStrip(double *x, double *y, double *z, unsigned int size) {
  this->size = size;
  double minx = 9e6, miny = 9e6, minz = 9e6, maxx = -9e6, maxy = -9e6,
         maxz = -9e6;
  // values = new double[size*3];
  for (unsigned int i = 0; i < size; i++) {
    values[i * 3] = x[i];
    values[i * 3 + 1] = y[i];
    values[i * 3 + 2] = z[i];
    minx = std::min(minx, (double)(x[i]));
    miny = std::min(miny, (double)(y[i]));
    minz = std::min(minz, 0.0);
    maxx = std::max(maxx, (double)(x[i]));
    maxy = std::max(maxy, (double)(y[i]));
    maxz = std::max(maxz, 0.0);
  }
  setBoundMax(maxx, maxy, maxz);
  setBoundMin(minx, miny, minz);
}
TriStrip::~TriStrip() {
  // delete[] values;
}
void TriStrip::display(double dx, double dy, double dz) {
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
  glBegin(GL_TRIANGLE_STRIP);
  glColor4d(LineColor[0], LineColor[1], LineColor[2], LineColor[3]);
  for (unsigned int i = 0; i < size; i++) {
    glColor4d(FillColor[0], FillColor[1], FillColor[2], FillColor[3]);
    glVertex3d(values[i * 3 + 0] + dx, values[i * 3 + 1] + dy,
               values[i * 3 + 2] + dz);
  }
  glEnd();
}
void TriStrip::generateMCode(MStream *out, std::string hashtag) {}
void TriStrip::generatePCode(PStream *out, int d, std::string hashtag) {}
}  // namespace PlotLab
}  // namespace DLR